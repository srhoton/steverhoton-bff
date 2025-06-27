# Common VTL templates for Lambda resolvers
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