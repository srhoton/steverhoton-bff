# Parts API GraphQL Test Queries

## 1. Create Part Mutation

```graphql
mutation CreatePart {
  createPart(input: {
    accountId: "test-account-123"
    locationId: "550e8400-e29b-41d4-a716-446655440000"
    partNumber: "BRAKE-001"
    description: "High-Performance Ceramic Brake Pads"
    manufacturer: "BremboTech"
    category: "Brake System"
    subcategory: "Brake Pads"
    condition: "new"
    status: "available"
    quantity: 25
    serialNumber: "BT-001-2024"
    vendor: "Auto Parts Wholesale"
    weight: 5.5
    specifications: "{\"material\":\"ceramic\",\"compatibility\":\"universal\",\"temperature_range\":\"200-800C\"}"
    extendedAttributes: "{\"pies_item_id\":\"12345\",\"warranty_months\":24}"
    tags: ["brake", "ceramic", "high-performance"]
    notes: "Premium ceramic brake pads for high-performance vehicles"
  }) {
    accountId
    sortKey
    partNumber
    description
    manufacturer
    category
    subcategory
    locationId
    condition
    status
    quantity
    serialNumber
    vendor
    weight
    specifications
    extendedAttributes
    tags
    notes
  }
}
```

## 2. List Parts Query

```graphql
query ListParts {
  listParts(input: {
    accountId: "test-account-123"
    limit: 10
  }) {
    parts {
      accountId
      sortKey
      partNumber
      description
      manufacturer
      category
      subcategory
      locationId
      unitId
      condition
      status
      quantity
      serialNumber
      vendor
      weight
      tags
      notes
    }
    nextToken
  }
}
```

## 3. Get Specific Part Query

```graphql
query GetPart {
  getPart(input: {
    accountId: "test-account-123"
    sortKey: "location#550e8400-e29b-41d4-a716-446655440000"
  }) {
    accountId
    sortKey
    partNumber
    description
    manufacturer
    category
    subcategory
    locationId
    condition
    status
    quantity
    serialNumber
    vendor
    weight
    specifications
    extendedAttributes
    tags
    notes
  }
}
```

## 4. Get Parts by Location Query

```graphql
query GetPartsByLocation {
  getPartsByLocation(
    accountId: "test-account-123"
    locationId: "550e8400-e29b-41d4-a716-446655440000"
    limit: 10
  ) {
    parts {
      accountId
      sortKey
      partNumber
      description
      manufacturer
      category
      condition
      status
      quantity
      locationId
      tags
    }
    nextToken
  }
}
```

## 5. Get Parts by Unit Query (if you have unit-based parts)

```graphql
query GetPartsByUnit {
  getPartsByUnit(
    accountId: "test-account-123"
    unitId: "unit-456"
    limit: 10
  ) {
    parts {
      accountId
      sortKey
      partNumber
      description
      manufacturer
      category
      condition
      status
      quantity
      unitId
      tags
    }
    nextToken
  }
}
```

## 6. Update Part Mutation

```graphql
mutation UpdatePart {
  updatePart(input: {
    accountId: "test-account-123"
    sortKey: "location#550e8400-e29b-41d4-a716-446655440000"
    quantity: 20
    status: "installed"
    notes: "Updated: Part moved to active inventory"
  }) {
    accountId
    sortKey
    partNumber
    description
    quantity
    status
    notes
  }
}
```

**Note**: Valid status values are: `available`, `installed`, `reserved`, `maintenance`, `disposed`

## 7. Delete Part Mutation

```graphql
mutation DeletePart {
  deletePart(input: {
    accountId: "test-account-123"
    sortKey: "location#550e8400-e29b-41d4-a716-446655440000"
  }) {
    success
    message
  }
}
```

## Testing Notes

1. **Authentication**: All queries require authentication via Cognito User Pools
2. **Account ID**: Use your actual account ID instead of "test-account-123"
3. **Location/Unit IDs**: Use valid location or unit IDs from your system
4. **Sort Key Format**: The sortKey follows the pattern `location#<locationId>` or `unit#<unitId>`
5. **Specifications/ExtendedAttributes**: These are JSON strings, ensure proper escaping
6. **Testing Order**: 
   - Start with `createPart`
   - Then test `listParts` and `getPart`
   - Test `updatePart`
   - Finally test `deletePart`

## GraphQL Endpoint

Your GraphQL endpoint should be available at:
```
https://bff.steverhoton.com/graphql
```

Use tools like:
- GraphQL Playground
- Postman
- Apollo Studio
- curl with proper authentication headers