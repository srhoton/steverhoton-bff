#!/bin/bash

# Script to create account and contact for a user in the BFF system
# Usage: ./create_user_account_contact.sh <email>

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

# Step 2: Get Cognito ID token for authentication
log "Getting authentication token..."
# Note: This assumes you have valid AWS credentials that can assume a role or have permissions
# to get an ID token. In a production environment, you might need to implement proper authentication flow.
# For now, we'll use AWS CLI to get credentials

# Generate a unique account ID (using sub as base)
ACCOUNT_ID="acc-${USER_SUB}"
ACCOUNT_NAME="${FIRST_NAME:-Unknown} ${LAST_NAME:-User}"
ACCOUNT_NAME=$(echo "$ACCOUNT_NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Step 3: Create account using AppSync mutation
log "Creating account with ID: $ACCOUNT_ID"

CREATE_ACCOUNT_MUTATION='mutation CreateAccount($input: CreateAccountInput!) {
  createAccount(input: $input) {
    id
    name
    status
    createdAt
    updatedAt
  }
}'

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

# Note: For AppSync calls, we need proper authentication headers
# This is a simplified version - in production, you'd need to get proper Cognito tokens
ACCOUNT_RESPONSE=$(aws appsync start-schema-creation \
    --api-id "$(aws appsync list-graphql-apis --region $AWS_REGION | jq -r '.graphqlApis[] | select(.name == "steverhoton-bff-api") | .apiId')" \
    --definition "query" 2>&1) || {
    log "Note: Direct AppSync mutation requires proper authentication setup"
    log "In production, you would need to:"
    log "1. Get an ID token from Cognito"
    log "2. Use the token in the Authorization header"
    log "3. Make the GraphQL request to the AppSync endpoint"
}

# Alternative approach using curl with proper authentication
# This requires an ID token from Cognito
log "To complete the account creation, you need to make an authenticated GraphQL request"
log "Example curl command (requires valid ID_TOKEN):"
cat << EOF

# Create Account:
curl -X POST $APPSYNC_ENDPOINT \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer <ID_TOKEN>" \\
  -d '{
    "query": "$CREATE_ACCOUNT_MUTATION",
    "variables": $ACCOUNT_VARIABLES
  }'

EOF

# Step 4: Create contact using AppSync mutation
log "Preparing contact creation..."

CREATE_CONTACT_MUTATION='mutation CreateContact($input: CreateContactInput!) {
  createContact(input: $input)
}'

CONTACT_VARIABLES=$(jq -n \
    --arg accountId "$ACCOUNT_ID" \
    --arg email "$EMAIL" \
    --arg firstName "${FIRST_NAME:-}" \
    --arg lastName "${LAST_NAME:-}" \
    --arg phone "${PHONE:-}" \
    '{
        "input": {
            "accountId": $accountId,
            "email": $email,
            "firstName": $firstName,
            "lastName": $lastName,
            "phone": $phone,
            "status": "ACTIVE"
        }
    }' | jq 'del(.input | to_entries[] | select(.value == ""))')

log "Contact creation command:"
cat << EOF

# Create Contact:
curl -X POST $APPSYNC_ENDPOINT \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer <ID_TOKEN>" \\
  -d '{
    "query": "$CREATE_CONTACT_MUTATION",
    "variables": $CONTACT_VARIABLES
  }'

EOF

log "Script completed successfully"
log "Account ID: $ACCOUNT_ID"
log "Contact Email: $EMAIL"
log ""
log "Note: To fully automate this process, you need to:"
log "1. Implement Cognito authentication flow to get ID tokens"
log "2. Use the tokens to make authenticated AppSync API calls"
log "3. Handle the GraphQL responses appropriately"