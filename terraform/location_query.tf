# Local values for location query resolver
locals {
  # Lambda function name for location resolver
  location_lambda_function_name = "location-prod-location-handler"

  # Request template for location resolver (passes through AppSync event structure)
  location_request_template = <<EOF
{
  "version": "2017-02-28",
  "operation": "Invoke",
  "payload": {
    "field": $util.toJson($context.info.fieldName),
    "arguments": $util.toJson($context.arguments.input),
    "identity": $util.toJson($context.identity),
    "request": $util.toJson($context.request),
    "source": $util.toJson($context.source)
  }
}
EOF

  # Response template for location resolver
  location_response_template = <<EOF
$util.toJson($context.result)
EOF
}

# Data source for existing location lambda function
data "aws_lambda_function" "location_resolver" {
  function_name = local.location_lambda_function_name
}

# IAM role for AppSync to invoke location Lambda
resource "aws_iam_role" "appsync_location_lambda_role" {
  name = "${var.project}-appsync-location-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "appsync.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for AppSync to invoke the location lambda
resource "aws_iam_role_policy" "appsync_location_lambda_policy" {
  name = "${var.project}-appsync-location-lambda-policy"
  role = aws_iam_role.appsync_location_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          data.aws_lambda_function.location_resolver.arn
        ]
      }
    ]
  })
}

# AppSync Data Source for location lambda
resource "aws_appsync_datasource" "location_lambda" {
  api_id           = aws_appsync_graphql_api.bff_api.id
  name             = "location_lambda"
  type             = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_location_lambda_role.arn

  lambda_config {
    function_arn = data.aws_lambda_function.location_resolver.arn
  }
}

# AppSync Resolver for getLocation query
resource "aws_appsync_resolver" "get_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "getLocation"
  type        = "Query"

  request_template  = local.location_request_template
  response_template = local.location_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for listLocations query
resource "aws_appsync_resolver" "list_locations" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "listLocations"
  type        = "Query"

  request_template  = local.location_request_template
  response_template = local.location_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for createLocation mutation
resource "aws_appsync_resolver" "create_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "createLocation"
  type        = "Mutation"

  request_template  = local.location_request_template
  response_template = local.location_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for createAddressLocation mutation
resource "aws_appsync_resolver" "create_address_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "createAddressLocation"
  type        = "Mutation"

  request_template  = local.location_request_template
  response_template = local.location_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for createCoordinatesLocation mutation
resource "aws_appsync_resolver" "create_coordinates_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "createCoordinatesLocation"
  type        = "Mutation"

  request_template  = local.location_request_template
  response_template = local.location_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for updateLocation mutation
resource "aws_appsync_resolver" "update_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "updateLocation"
  type        = "Mutation"

  request_template  = local.location_request_template
  response_template = local.location_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for updateAddressLocation mutation
resource "aws_appsync_resolver" "update_address_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "updateAddressLocation"
  type        = "Mutation"

  request_template  = local.location_request_template
  response_template = local.location_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for updateCoordinatesLocation mutation
resource "aws_appsync_resolver" "update_coordinates_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "updateCoordinatesLocation"
  type        = "Mutation"

  request_template  = local.location_request_template
  response_template = local.location_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for deleteLocation mutation
resource "aws_appsync_resolver" "delete_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.location_lambda.name
  field       = "deleteLocation"
  type        = "Mutation"

  request_template  = local.location_request_template
  response_template = local.location_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}