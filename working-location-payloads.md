# Working Location CRUD Payloads

These payloads have been tested and confirmed working with the deployed AppSync API.

## Prerequisites

1. Obtain an authentication token from Cognito
2. Set the Authorization header: `Authorization: Bearer <token>`
3. GraphQL endpoint: `https://bff.steverhoton.com/graphql`

## 1. Create Address Location

```json
{
  "query": "mutation CreateAddressLocation($input: CreateAddressLocationInput!) { createAddressLocation(input: $input) }",
  "variables": {
    "input": {
      "accountId": "e4c8f468-e0b1-7049-6f0f-48b0b4f27aa5",
      "address": {
        "streetAddress": "123 Test Street",
        "streetAddress2": "Suite 100",
        "city": "Test City", 
        "stateProvince": "CA",
        "postalCode": "12345",
        "country": "US"
      },
      "extendedAttributes": "{\"key\": \"value\"}"
    }
  }
}
```

**Response:**
```json
{
  "data": {
    "createAddressLocation": "<location-id>"
  }
}
```

## 2. Get Location

```json
{
  "query": "query GetLocation($accountId: String!, $locationId: String!) { getLocation(accountId: $accountId, locationId: $locationId) { __typename ... on AddressLocation { locationId accountId locationType extendedAttributes address { streetAddress streetAddress2 city stateProvince postalCode country } } ... on CoordinatesLocation { locationId accountId locationType extendedAttributes coordinates { latitude longitude altitude accuracy } } } }",
  "variables": {
    "accountId": "e4c8f468-e0b1-7049-6f0f-48b0b4f27aa5",
    "locationId": "<location-id>"
  }
}
```

## 3. List Locations

```json
{
  "query": "query ListLocations($accountId: String!, $options: ListLocationsOptions) { listLocations(accountId: $accountId, options: $options) { locations { __typename ... on AddressLocation { locationId accountId locationType extendedAttributes address { streetAddress streetAddress2 city stateProvince postalCode country } } ... on CoordinatesLocation { locationId accountId locationType extendedAttributes coordinates { latitude longitude altitude accuracy } } } nextCursor } }",
  "variables": {
    "accountId": "e4c8f468-e0b1-7049-6f0f-48b0b4f27aa5",
    "options": {
      "limit": 10
    }
  }
}
```

## 4. Update Address Location

```json
{
  "query": "mutation UpdateAddressLocation($locationId: String!, $input: UpdateAddressLocationInput!) { updateAddressLocation(locationId: $locationId, input: $input) }",
  "variables": {
    "locationId": "<location-id>",
    "input": {
      "accountId": "e4c8f468-e0b1-7049-6f0f-48b0b4f27aa5",
      "address": {
        "streetAddress": "456 Updated Street",
        "streetAddress2": "Floor 2",
        "city": "Updated City",
        "stateProvince": "NY",
        "postalCode": "54321",
        "country": "US"
      },
      "extendedAttributes": "{\"key\": \"updatedValue\"}"
    }
  }
}
```

**Response:**
```json
{
  "data": {
    "updateAddressLocation": true
  }
}
```

## 5. Delete Location

```json
{
  "query": "mutation DeleteLocation($accountId: String!, $locationId: String!) { deleteLocation(accountId: $accountId, locationId: $locationId) }",
  "variables": {
    "accountId": "e4c8f468-e0b1-7049-6f0f-48b0b4f27aa5",
    "locationId": "<location-id>"
  }
}
```

**Response:**
```json
{
  "data": {
    "deleteLocation": true
  }
}
```

## Important Notes

1. **Country Code**: Must be a 2-character ISO 3166-1 alpha-2 code (e.g., "US", not "USA")
2. **Extended Attributes**: Must be a JSON string, not a JSON object
3. **Account ID**: Use the raw UUID without "acc-" prefix
4. **Location Type**: Automatically injected by the resolver based on the mutation type (createAddressLocation vs createCoordinatesLocation)

## Troubleshooting

### Issue Fixed: "unknown location type"
The Lambda expects a `locationType` field in the input, but the GraphQL schema doesn't include it. This was fixed by updating the AppSync resolver templates to inject the locationType based on the mutation being called:
- `createAddressLocation` → injects `"locationType": "address"`
- `createCoordinatesLocation` → injects `"locationType": "coordinates"`

### Test Script
A complete test script is available at: `/complete-location-crud-test.sh`