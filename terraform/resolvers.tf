# Common VTL templates for Lambda resolvers
locals {
  # Location Lambda request template for getLocation (direct parameters)
  location_get_request_template = <<EOF
{
  "version": "2018-05-29",
  "operation": "Invoke",
  "payload": {
    "field": "$context.info.fieldName",
    "arguments": $util.toJson($context.arguments)
  }
}
EOF

  # Location Lambda request template for listLocations (with options parameter)
  location_list_request_template = <<EOF
{
  "version": "2018-05-29",
  "operation": "Invoke",
  "payload": {
    "field": "$context.info.fieldName",
    "arguments": $util.toJson($context.arguments)
  }
}
EOF

  # Location Lambda request template for createAddressLocation
  location_create_address_request_template = <<EOF
{
  "version": "2018-05-29",
  "operation": "Invoke",
  "payload": {
    "field": "$context.info.fieldName",
    "arguments": {
      "input": {
        "accountId": "$context.arguments.input.accountId",
        "locationType": "address",
        "address": $util.toJson($context.arguments.input.address),
        "extendedAttributes": $util.toJson($context.arguments.input.extendedAttributes)
      }
    }
  }
}
EOF

  # Location Lambda request template for createCoordinatesLocation
  location_create_coordinates_request_template = <<EOF
{
  "version": "2018-05-29",
  "operation": "Invoke",
  "payload": {
    "field": "$context.info.fieldName",
    "arguments": {
      "input": {
        "accountId": "$context.arguments.input.accountId",
        "locationType": "coordinates",
        "coordinates": $util.toJson($context.arguments.input.coordinates),
        "extendedAttributes": $util.toJson($context.arguments.input.extendedAttributes)
      }
    }
  }
}
EOF

  # Location Lambda request template for updateAddressLocation
  location_update_address_request_template = <<EOF
{
  "version": "2018-05-29",
  "operation": "Invoke",
  "payload": {
    "field": "$context.info.fieldName",
    "arguments": {
      "locationId": "$context.arguments.locationId",
      "input": {
        "accountId": "$context.arguments.input.accountId",
        "locationType": "address",
        "address": $util.toJson($context.arguments.input.address),
        "extendedAttributes": $util.toJson($context.arguments.input.extendedAttributes)
      }
    }
  }
}
EOF

  # Location Lambda request template for updateCoordinatesLocation
  location_update_coordinates_request_template = <<EOF
{
  "version": "2018-05-29",
  "operation": "Invoke",
  "payload": {
    "field": "$context.info.fieldName",
    "arguments": {
      "locationId": "$context.arguments.locationId",
      "input": {
        "accountId": "$context.arguments.input.accountId",
        "locationType": "coordinates",
        "coordinates": $util.toJson($context.arguments.input.coordinates),
        "extendedAttributes": $util.toJson($context.arguments.input.extendedAttributes)
      }
    }
  }
}
EOF

  # Location Lambda request template for delete operations (direct parameters)
  location_delete_request_template = <<EOF
{
  "version": "2018-05-29",
  "operation": "Invoke",
  "payload": {
    "field": "$context.info.fieldName",
    "arguments": $util.toJson($context.arguments)
  }
}
EOF

  # Location Lambda response template
  location_response_template = <<EOF
#if($context.error)
  $util.error($context.error.message, $context.error.type)
#end

#if($context.result.errorType)
  $util.error($context.result.errorMessage, $context.result.errorType)
#end

$util.toJson($context.result)
EOF

}

# Units Lambda Templates
locals {
  # Request template for operations with input parameters (listUnits, createUnit, updateUnit)
  lambda_input_request_template = <<EOF
{
  "version": "2018-05-29",
  "operation": "Invoke",
  "payload": {
    "fieldName": "$context.info.fieldName",
    "arguments": $util.toJson($context.arguments.input),
    "identity": $util.toJson($context.identity),
    "source": $util.toJson($context.source),
    "request": $util.toJson($context.request),
    "prev": $util.toJson($context.prev)
  }
}
EOF

  # Request template for operations with direct parameters (getUnit, deleteUnit)
  lambda_direct_request_template = <<EOF
{
  "version": "2018-05-29",
  "operation": "Invoke",
  "payload": {
    "fieldName": "$context.info.fieldName",
    "arguments": $util.toJson($context.arguments),
    "identity": $util.toJson($context.identity),
    "source": $util.toJson($context.source),
    "request": $util.toJson($context.request),
    "prev": $util.toJson($context.prev)
  }
}
EOF

  # Response template for most Lambda resolvers
  lambda_response_template = <<EOF
#if($context.error)
  $util.error($context.error.message, $context.error.type)
#end

#if($context.result.errorType)
  $util.error($context.result.errorMessage, $context.result.errorType)
#end

$util.toJson($context.result.data)
EOF

  # Response template for delete operation (returns boolean)
  lambda_delete_response_template = <<EOF
#if($context.error)
  $util.error($context.error.message, $context.error.type)
#end

#if($context.result.errorType)
  $util.error($context.result.errorMessage, $context.result.errorType)
#end

#if($context.result.data.deleted)
  $context.result.data.deleted
#else
  $context.result.data
#end
EOF
}

# Query: getUnit (uses direct parameters: id, accountId)
resource "aws_appsync_resolver" "get_unit" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.unt_units_lambda.name
  field       = "getUnit"
  type        = "Query"

  request_template  = local.lambda_direct_request_template
  response_template = local.lambda_response_template
}

# Query: listUnits (uses input parameter)
resource "aws_appsync_resolver" "list_units" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.unt_units_lambda.name
  field       = "listUnits"
  type        = "Query"

  request_template  = local.lambda_input_request_template
  response_template = local.lambda_response_template
}

# Mutation: createUnit (uses input parameter)
resource "aws_appsync_resolver" "create_unit" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.unt_units_lambda.name
  field       = "createUnit"
  type        = "Mutation"

  request_template  = local.lambda_input_request_template
  response_template = local.lambda_response_template
}

# Mutation: updateUnit (uses input parameter)
resource "aws_appsync_resolver" "update_unit" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.unt_units_lambda.name
  field       = "updateUnit"
  type        = "Mutation"

  request_template  = local.lambda_input_request_template
  response_template = local.lambda_response_template
}

# Mutation: deleteUnit (uses direct parameters: id, accountId)
resource "aws_appsync_resolver" "delete_unit" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.unt_units_lambda.name
  field       = "deleteUnit"
  type        = "Mutation"

  request_template  = local.lambda_direct_request_template
  response_template = local.lambda_delete_response_template
}

# Location Resolvers

# Query: getLocation
resource "aws_appsync_resolver" "get_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "getLocation"
  type        = "Query"

  request_template  = local.location_get_request_template
  response_template = local.location_response_template
}

# Query: listLocations
resource "aws_appsync_resolver" "list_locations" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "listLocations"
  type        = "Query"

  request_template  = local.location_list_request_template
  response_template = local.location_response_template
}

# Mutation: createAddressLocation
resource "aws_appsync_resolver" "create_address_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "createAddressLocation"
  type        = "Mutation"

  request_template  = local.location_create_address_request_template
  response_template = local.location_response_template
}

# Mutation: createCoordinatesLocation
resource "aws_appsync_resolver" "create_coordinates_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "createCoordinatesLocation"
  type        = "Mutation"

  request_template  = local.location_create_coordinates_request_template
  response_template = local.location_response_template
}

# Mutation: updateAddressLocation
resource "aws_appsync_resolver" "update_address_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "updateAddressLocation"
  type        = "Mutation"

  request_template  = local.location_update_address_request_template
  response_template = local.location_response_template
}

# Mutation: updateCoordinatesLocation
resource "aws_appsync_resolver" "update_coordinates_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "updateCoordinatesLocation"
  type        = "Mutation"

  request_template  = local.location_update_coordinates_request_template
  response_template = local.location_response_template
}

# Mutation: deleteLocation
resource "aws_appsync_resolver" "delete_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "deleteLocation"
  type        = "Mutation"

  request_template  = local.location_delete_request_template
  response_template = local.location_response_template
}