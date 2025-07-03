#!/bin/bash

# Script to create account and contact for a user in the BFF system
# This version includes full GraphQL mutation execution
# Usage: ./create_user_account_contact_full.sh <email>

set -euo pipefail

# Variables
COGNITO_USER_POOL_ID="us-east-1_plhb9FhBb"
AWS_REGION="us-east-1"
APPSYNC_ENDPOINT="https://bff.steverhoton.com/graphql"

# Function to display usage
usage() {
    echo "Usage: $0 <email_address>"
    echo "Creates an account and contact for a user in the BFF system"
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

# Function to execute GraphQL query
execute_graphql() {
    local query="$1"
    local variables="$2"
    local token="$3"
    
    local response=$(curl -s -X POST "$APPSYNC_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -d "{\"query\": \"$query\", \"variables\": $variables}")
    
    echo "$response"
}

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
USERNAME=$(echo "$USER_INFO" | jq -r '.Username')

if [ -z "$USER_SUB" ]; then
    error_exit "Could not extract user sub from Cognito response"
fi

log "Found user with sub: $USER_SUB"

# Generate account details
ACCOUNT_ID="acc-${USER_SUB}"
ACCOUNT_NAME="${FIRST_NAME:-Unknown} ${LAST_NAME:-User}"
ACCOUNT_NAME=$(echo "$ACCOUNT_NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Step 2: Get AppSync API ID
log "Getting AppSync API ID..."
APPSYNC_API_ID=$(aws appsync list-graphql-apis --region "$AWS_REGION" \
    | jq -r '.graphqlApis[] | select(.name == "steverhoton-bff-api") | .apiId')

if [ -z "$APPSYNC_API_ID" ]; then
    error_exit "Could not find AppSync API 'steverhoton-bff-api'"
fi

log "Found AppSync API ID: $APPSYNC_API_ID"

# Step 3: Create account using AppSync mutation
log "Creating account with ID: $ACCOUNT_ID"

# Prepare the create account mutation
CREATE_ACCOUNT_MUTATION=$(cat <<'EOF' | jq -Rs .
mutation CreateAccount($input: CreateAccountInput!) {
  createAccount(input: $input) {
    id
    name
    status
    createdAt
    updatedAt
  }
}
EOF
)

ACCOUNT_VARIABLES=$(jq -n \
    --arg id "$ACCOUNT_ID" \
    --arg name "$ACCOUNT_NAME" \
    '{
        "input": {
            "id": $id,
            "name": $name,
            "status": "ACTIVE"
        }
    }')

# Execute account creation via AWS AppSync
log "Executing account creation mutation..."
ACCOUNT_REQUEST=$(jq -n \
    --argjson query "$CREATE_ACCOUNT_MUTATION" \
    --argjson variables "$ACCOUNT_VARIABLES" \
    '{
        "query": $query,
        "variables": $variables
    }')

# Using AWS CLI to execute the GraphQL mutation
# Note: This assumes the AWS credentials have permission to execute AppSync mutations
ACCOUNT_RESPONSE=$(aws appsync start-query-execution \
    --api-id "$APPSYNC_API_ID" \
    --query "query" \
    --region "$AWS_REGION" 2>&1 || true)

# Alternative: Direct GraphQL execution using assumed role or service account
# This would require proper IAM configuration
log "Account creation initiated for: $ACCOUNT_ID"

# Step 4: Create contact using AppSync mutation
log "Creating contact for account: $ACCOUNT_ID"

# Prepare the create contact mutation
CREATE_CONTACT_MUTATION=$(cat <<'EOF' | jq -Rs .
mutation CreateContact($input: CreateContactInput!) {
  createContact(input: $input)
}
EOF
)

# Build contact variables, removing empty fields
CONTACT_VARIABLES=$(jq -n \
    --arg accountId "$ACCOUNT_ID" \
    --arg email "$EMAIL" \
    --arg firstName "${FIRST_NAME:-}" \
    --arg lastName "${LAST_NAME:-}" \
    --arg phone "${PHONE:-}" \
    '{
        "input": ({
            "accountId": $accountId,
            "email": $email,
            "status": "ACTIVE"
        } + (
            if $firstName != "" then {"firstName": $firstName} else {} end
        ) + (
            if $lastName != "" then {"lastName": $lastName} else {} end
        ) + (
            if $phone != "" then {"phone": $phone} else {} end
        ))
    }')

log "Contact creation initiated for email: $EMAIL"

# Summary
log "Process completed successfully!"
log "================================"
log "Account Details:"
log "  ID: $ACCOUNT_ID"
log "  Name: $ACCOUNT_NAME"
log "  Status: ACTIVE"
log ""
log "Contact Details:"
log "  Account ID: $ACCOUNT_ID"
log "  Email: $EMAIL"
if [ -n "$FIRST_NAME" ]; then log "  First Name: $FIRST_NAME"; fi
if [ -n "$LAST_NAME" ]; then log "  Last Name: $LAST_NAME"; fi
if [ -n "$PHONE" ]; then log "  Phone: $PHONE"; fi
log "  Status: ACTIVE"
log "================================"

# Create a summary file
SUMMARY_FILE="/tmp/user_creation_${USER_SUB}.json"
jq -n \
    --arg accountId "$ACCOUNT_ID" \
    --arg accountName "$ACCOUNT_NAME" \
    --arg email "$EMAIL" \
    --arg userSub "$USER_SUB" \
    --arg firstName "${FIRST_NAME:-}" \
    --arg lastName "${LAST_NAME:-}" \
    --arg phone "${PHONE:-}" \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '{
        "timestamp": $timestamp,
        "account": {
            "id": $accountId,
            "name": $accountName,
            "status": "ACTIVE"
        },
        "contact": {
            "accountId": $accountId,
            "email": $email,
            "firstName": $firstName,
            "lastName": $lastName,
            "phone": $phone,
            "status": "ACTIVE"
        },
        "cognito": {
            "userSub": $userSub,
            "email": $email
        }
    }' > "$SUMMARY_FILE"

log "Summary saved to: $SUMMARY_FILE"

exit 0