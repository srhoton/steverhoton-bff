# Events Lambda Bug Reports and Resolutions

This document contains bug reports for issues discovered during testing of the events GraphQL API.

## Bug 1: Interface Conversion Error in Query Operations

### Summary
The events lambda function experienced interface conversion errors when handling GraphQL query operations.

### Error Details
- **Error Type**: `TypeAssertionError`
- **Error Message**: `interface conversion: interface {} is nil, not string`
- **Affected Operations**: getEvent, listEventsByUnit

### Resolution Status
✅ **FIXED** - Lambda was updated to properly handle query operations

### Test Verification
All query operations now work correctly:
- getEvent returns individual events
- listEventsByUnit returns all events for a unit
- listEventsByCategory filters by category
- listEventsByStatus filters by status

## Bug 2: DynamoDB Reserved Keyword Error

### Summary
The `listEventsByStatus` operation failed due to using the reserved keyword "status" in DynamoDB FilterExpression.

### Error Details
- **Error Type**: `DynamoDB ValidationException`
- **Error Message**: `Invalid FilterExpression: Attribute name is a reserved keyword; reserved keyword: status`
- **DynamoDB Request ID**: `69S97HPAEMCEH5AUP9CTRK5TOFVV4KQNSO5AEMVJF66Q9ASUAAJG`

### Root Cause
The lambda was using `status` directly in FilterExpression without escaping:
```javascript
// Broken
FilterExpression: "status = :statusValue"

// Fixed
FilterExpression: "#status = :statusValue"
ExpressionAttributeNames: { "#status": "status" }
```

### Resolution Status
✅ **FIXED** - Lambda now properly escapes the reserved keyword

## Bug 3: Overly Strict Validation in UpdateEvent

### Summary
The `updateEvent` mutation required `maintenanceDetails` for any update to maintenance events, even status-only updates.

### Error Details
- **Error Type**: Lambda validation error
- **Error Message**: `event validation failed: [(root): Must validate "then" as "if" was valid (root): maintenanceDetails is required`
- **Affected Event Types**: Maintenance category events

### Root Cause
Conditional schema validation (`if/then`) was too strict, requiring category-specific details for simple status updates.

### Resolution Status
✅ **FIXED** - Lambda validation now allows partial updates for status-only changes

### Test Verification
Status-only updates now work for all event types:
- Maintenance events can be updated without maintenanceDetails
- Fault events continue to work as before
- Invalid status values are still properly rejected

## Test Event IDs for Reference
- **Maintenance Event**: `defead90-5324-4847-a1cb-bc057171e03f` (scheduled_service)
- **Fault Event**: `eba7e20a-1ef6-4cfa-855e-e75369cb2900` (brake_fault)
- **Unit ID**: `26e50d66-5e4c-4808-ac79-99754b8f40f6`
- **Account ID**: `e4c8f468-e0b1-7049-6f0f-48b0b4f27aa5`

## Valid Event Status Values
```
"created", "acknowledged", "in_progress", "resolved", 
"closed", "cancelled", "on_hold", "escalated"
```