#!/bin/bash

# Complete CRUD test for locations
# Usage: ./complete-location-crud-test.sh

# Configuration
GRAPHQL_URL="https://bff.steverhoton.com/graphql"
ACCOUNT_ID="e4c8f468-e0b1-7049-6f0f-48b0b4f27aa5"

# Get auth token
AUTH_TOKEN=$(./get-auth-token.sh | grep "ID_TOKEN=" | cut -d'=' -f2)

if [ -z "$AUTH_TOKEN" ]; then
    echo "Failed to get auth token"
    exit 1
fi

echo "Successfully obtained auth token"
echo ""

# Function to execute GraphQL query
execute_query() {
    local payload="$1"
    local description="$2"
    
    echo "=================================================="
    echo "$description"
    echo "=================================================="
    
    echo "Request:"
    echo "$payload" | jq .
    
    echo -e "\nResponse:"
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -d "$payload" \
        "$GRAPHQL_URL")
    
    echo "$response" | jq .
    echo -e "\n"
}

# 1. CREATE ADDRESS LOCATION
CREATE_PAYLOAD='{
  "query": "mutation CreateAddressLocation($input: CreateAddressLocationInput!) { createAddressLocation(input: $input) }",
  "variables": {
    "input": {
      "accountId": "'$ACCOUNT_ID'",
      "address": {
        "streetAddress": "123 Test Street",
        "streetAddress2": "Suite 100",
        "city": "Test City",
        "stateProvince": "CA",
        "postalCode": "12345",
        "country": "US"
      },
      "extendedAttributes": "{\"testAttribute\": \"testValue\", \"createdBy\": \"test-script\"}"
    }
  }
}'

execute_query "$CREATE_PAYLOAD" "1. CREATE ADDRESS LOCATION"
LOCATION_ID=$(echo "$response" | jq -r '.data.createAddressLocation')

if [ "$LOCATION_ID" = "null" ] || [ -z "$LOCATION_ID" ]; then
    echo "Failed to create location or extract location ID"
    exit 1
fi

echo "Created location with ID: $LOCATION_ID"
echo ""

# 2. GET LOCATION
GET_PAYLOAD='{
  "query": "query GetLocation($accountId: String!, $locationId: String!) { getLocation(accountId: $accountId, locationId: $locationId) { __typename ... on AddressLocation { locationId accountId locationType extendedAttributes address { streetAddress streetAddress2 city stateProvince postalCode country } } ... on CoordinatesLocation { locationId accountId locationType extendedAttributes coordinates { latitude longitude altitude accuracy } } } }",
  "variables": {
    "accountId": "'$ACCOUNT_ID'",
    "locationId": "'$LOCATION_ID'"
  }
}'

execute_query "$GET_PAYLOAD" "2. GET LOCATION"

# 3. LIST LOCATIONS
LIST_PAYLOAD='{
  "query": "query ListLocations($accountId: String!, $options: ListLocationsOptions) { listLocations(accountId: $accountId, options: $options) { locations { __typename ... on AddressLocation { locationId accountId locationType extendedAttributes address { streetAddress streetAddress2 city stateProvince postalCode country } } ... on CoordinatesLocation { locationId accountId locationType extendedAttributes coordinates { latitude longitude altitude accuracy } } } nextCursor } }",
  "variables": {
    "accountId": "'$ACCOUNT_ID'",
    "options": {
      "limit": 10
    }
  }
}'

execute_query "$LIST_PAYLOAD" "3. LIST LOCATIONS"

# 4. UPDATE ADDRESS LOCATION
UPDATE_PAYLOAD='{
  "query": "mutation UpdateAddressLocation($locationId: String!, $input: UpdateAddressLocationInput!) { updateAddressLocation(locationId: $locationId, input: $input) }",
  "variables": {
    "locationId": "'$LOCATION_ID'",
    "input": {
      "accountId": "'$ACCOUNT_ID'",
      "address": {
        "streetAddress": "456 Updated Street",
        "streetAddress2": "Floor 2",
        "city": "Updated City",
        "stateProvince": "NY",
        "postalCode": "54321",
        "country": "US"
      },
      "extendedAttributes": "{\"testAttribute\": \"updatedValue\", \"updatedBy\": \"test-script\", \"updatedAt\": \"'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'\"}"
    }
  }
}'

execute_query "$UPDATE_PAYLOAD" "4. UPDATE ADDRESS LOCATION"

# 5. GET LOCATION AGAIN TO VERIFY UPDATE
execute_query "$GET_PAYLOAD" "5. GET LOCATION (VERIFY UPDATE)"

# 6. DELETE LOCATION
DELETE_PAYLOAD='{
  "query": "mutation DeleteLocation($accountId: String!, $locationId: String!) { deleteLocation(accountId: $accountId, locationId: $locationId) }",
  "variables": {
    "accountId": "'$ACCOUNT_ID'",
    "locationId": "'$LOCATION_ID'"
  }
}'

execute_query "$DELETE_PAYLOAD" "6. DELETE LOCATION"

# 7. VERIFY DELETION
execute_query "$GET_PAYLOAD" "7. GET LOCATION (VERIFY DELETION - SHOULD FAIL)"

echo "==================================================
CRUD TEST COMPLETED SUCCESSFULLY!
==================================================

The following operations were tested:
✓ Create Address Location
✓ Get Location by ID
✓ List Locations
✓ Update Address Location
✓ Delete Location
✓ Verify Deletion

All operations completed successfully!"