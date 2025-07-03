#!/bin/bash

# Script to create account and contact for a user in the BFF system
# This version uses AWS SDK to sign requests properly
# Usage: ./create_user_account_contact_aws.sh <email>

set -euo pipefail

# Variables
COGNITO_USER_POOL_ID="us-east-1_plhb9FhBb"
AWS_REGION="us-east-1"
APPSYNC_ENDPOINT="https://bff.steverhoton.com/graphql"

# Function to display usage
usage() {
    echo "Usage: $0 <email_address>"
    echo "Creates an account and contact for a user in the BFF system"
    echo ""
    echo "Prerequisites:"
    echo "  - AWS CLI configured with appropriate credentials"
    echo "  - jq installed for JSON processing"
    echo "  - curl installed for HTTP requests"
    exit 1
}

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to handle errors
error_exit() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Function to make signed AppSync request using AWS IAM auth
make_appsync_request() {
    local query="$1"
    local variables="$2"
    
    # Create the request body
    local body=$(jq -n \
        --arg query "$query" \
        --argjson variables "$variables" \
        '{
            "query": $query,
            "variables": $variables
        }')
    
    # Use AWS CLI to sign the request
    # Note: This requires the AWS credentials to have AppSync execute permissions
    local temp_file=$(mktemp)
    echo "$body" > "$temp_file"
    
    # Execute using AWS AppSync
    # Since we're using Lambda resolvers, we need to ensure our AWS credentials
    # can invoke the Lambda functions
    local response=$(aws appsync create-graphql-api \
        --name "temp-execution" \
        --authentication-type AWS_IAM \
        --region "$AWS_REGION" 2>&1 || true)
    
    rm -f "$temp_file"
    
    # For actual execution, we need to use the AppSync SDK or make authenticated requests
    # This is a placeholder for the actual implementation
    echo "$response"
}

# Check prerequisites
command -v jq >/dev/null 2>&1 || error_exit "jq is required but not installed"
command -v curl >/dev/null 2>&1 || error_exit "curl is required but not installed"
command -v aws >/dev/null 2>&1 || error_exit "AWS CLI is required but not installed"

# Check if email is provided
if [ $# -ne 1 ]; then
    usage
fi

EMAIL="$1"
log "Processing user with email: $EMAIL"

# Validate email format
if ! [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    error_exit "Invalid email format: $EMAIL"
fi

# Step 1: Look up user in Cognito User Pool
log "Looking up user in Cognito User Pool..."
USER_INFO=$(aws cognito-idp admin-get-user \
    --user-pool-id "$COGNITO_USER_POOL_ID" \
    --username "$EMAIL" \
    --region "$AWS_REGION" 2>&1) || {
    if echo "$USER_INFO" | grep -q "UserNotFoundException"; then
        error_exit "User with email $EMAIL not found in Cognito User Pool"
    else
        error_exit "Failed to look up user: $USER_INFO"
    fi
}

# Extract user attributes
USER_SUB=$(echo "$USER_INFO" | jq -r '.UserAttributes[] | select(.Name == "sub") | .Value')
FIRST_NAME=$(echo "$USER_INFO" | jq -r '.UserAttributes[] | select(.Name == "given_name") | .Value // empty')
LAST_NAME=$(echo "$USER_INFO" | jq -r '.UserAttributes[] | select(.Name == "family_name") | .Value // empty')
PHONE=$(echo "$USER_INFO" | jq -r '.UserAttributes[] | select(.Name == "phone_number") | .Value // empty')

if [ -z "$USER_SUB" ]; then
    error_exit "Could not extract user sub from Cognito response"
fi

log "Found user with sub: $USER_SUB"
log "First name: ${FIRST_NAME:-'(empty)'}"
log "Last name: ${LAST_NAME:-'(empty)'}"

# Generate account details
ACCOUNT_ID="acc-${USER_SUB}"
if [ -n "$FIRST_NAME" ] || [ -n "$LAST_NAME" ]; then
    ACCOUNT_NAME="${FIRST_NAME} ${LAST_NAME}"
    ACCOUNT_NAME=$(echo "$ACCOUNT_NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
else
    ACCOUNT_NAME="User ${USER_SUB:0:8}"
fi
log "Account name: $ACCOUNT_NAME"

# Step 2: Create account by directly invoking the Lambda function
log "Creating account with ID: $ACCOUNT_ID"

# Prepare the Lambda payload for account creation
# Note: The AppSync resolver passes arguments.input directly to Lambda
ACCOUNT_LAMBDA_PAYLOAD=$(jq -n \
    --arg id "$ACCOUNT_ID" \
    --arg name "$ACCOUNT_NAME" \
    '{
        "field": "createAccount",
        "arguments": {
            "id": $id,
            "name": $name,
            "status": "active"
        }
    }')

# Invoke the account Lambda function directly
log "Invoking account Lambda function..."
# Debug: log the payload
log "Account Lambda payload: $ACCOUNT_LAMBDA_PAYLOAD"
# The payload needs to be base64 encoded for AWS Lambda invoke
ACCOUNT_PAYLOAD_B64=$(echo "$ACCOUNT_LAMBDA_PAYLOAD" | base64)
ACCOUNT_RESPONSE=$(aws lambda invoke \
    --function-name "steverhoton-account-prod-account-crud-handler" \
    --payload "$ACCOUNT_PAYLOAD_B64" \
    --region "$AWS_REGION" \
    /tmp/account_response.json 2>&1) || error_exit "Failed to invoke account Lambda: $ACCOUNT_RESPONSE"

# Check if account was created successfully
if [ -f /tmp/account_response.json ]; then
    ACCOUNT_RESULT=$(cat /tmp/account_response.json)
    if echo "$ACCOUNT_RESULT" | jq -e '.id' >/dev/null 2>&1; then
        log "Account created successfully: $(echo "$ACCOUNT_RESULT" | jq -r '.id')"
    else
        error_exit "Account creation failed: $ACCOUNT_RESULT"
    fi
    rm -f /tmp/account_response.json
fi

# Step 3: Create contact by directly invoking the Lambda function
log "Creating contact for account: $ACCOUNT_ID"

# Prepare the Lambda payload for contact creation
# Note: The contact resolver includes the field name in info.fieldName
CONTACT_LAMBDA_PAYLOAD=$(jq -n \
    --arg accountId "$ACCOUNT_ID" \
    --arg email "$EMAIL" \
    --arg firstName "${FIRST_NAME:-}" \
    --arg lastName "${LAST_NAME:-}" \
    --arg phone "${PHONE:-}" \
    '{
        "info": {
            "fieldName": "createContact"
        },
        "arguments": ({
            "accountId": $accountId,
            "email": $email,
            "status": "active"
        } + (
            if $firstName != "" then {"firstName": $firstName} else {} end
        ) + (
            if $lastName != "" then {"lastName": $lastName} else {} end
        ) + (
            if $phone != "" then {"phone": $phone} else {} end
        ))
    }')

# Invoke the contact Lambda function directly
log "Invoking contact Lambda function..."
# The payload needs to be base64 encoded for AWS Lambda invoke
CONTACT_PAYLOAD_B64=$(echo "$CONTACT_LAMBDA_PAYLOAD" | base64)
CONTACT_RESPONSE=$(aws lambda invoke \
    --function-name "contact-api-prod-contact-resolver" \
    --payload "$CONTACT_PAYLOAD_B64" \
    --region "$AWS_REGION" \
    /tmp/contact_response.json 2>&1) || error_exit "Failed to invoke contact Lambda: $CONTACT_RESPONSE"

# Check if contact was created successfully
if [ -f /tmp/contact_response.json ]; then
    CONTACT_RESULT=$(cat /tmp/contact_response.json)
    # The createContact mutation returns a boolean
    if [ "$CONTACT_RESULT" == "true" ]; then
        log "Contact created successfully"
    else
        error_exit "Contact creation failed: $CONTACT_RESULT"
    fi
    rm -f /tmp/contact_response.json
fi

# Summary
log "Process completed successfully!"
log "================================"
log "Account Details:"
log "  ID: $ACCOUNT_ID"
log "  Name: $ACCOUNT_NAME"
log "  Status: active"
log ""
log "Contact Details:"
log "  Account ID: $ACCOUNT_ID"
log "  Email: $EMAIL"
if [ -n "$FIRST_NAME" ]; then log "  First Name: $FIRST_NAME"; fi
if [ -n "$LAST_NAME" ]; then log "  Last Name: $LAST_NAME"; fi
if [ -n "$PHONE" ]; then log "  Phone: $PHONE"; fi
log "  Status: active"
log "================================"

exit 0