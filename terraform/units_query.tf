# Local values for units query resolver
locals {
  # Lambda function name for units resolver
  units_lambda_function_name = "unt-units-svc-prod-lambda"

  # Request template for units resolver (passes input directly to match CreateUnitInput structure)
  units_request_template = <<EOF
{
  "version": "2017-02-28",
  "operation": "Invoke",
  "payload": {
    "typeName": $util.toJson($context.info.parentTypeName),
    "fieldName": $util.toJson($context.info.fieldName),
    "arguments": $util.toJson($context.arguments.input),
    "identity": $util.toJson($context.identity),
    "source": $util.toJson($context.source),
    "request": $util.toJson($context.request),
    "info": {
      "fieldName": $util.toJson($context.info.fieldName),
      "parentTypeName": $util.toJson($context.info.parentTypeName),
      "variables": $util.toJson($context.info.variables),
      "selectionSetList": $util.toJson($context.info.selectionSetList)
    },
    "prev": $util.toJson($context.prev)
  }
}
EOF

  # Response template for units resolver
  units_response_template = <<EOF
## Units lambda returns {success: bool, data: interface{}, message: string, error: *ErrorInfo} format
## Pass through the complete response structure
$util.toJson($context.result)
EOF
}

# Data source for existing units lambda function
data "aws_lambda_function" "units_resolver" {
  function_name = local.units_lambda_function_name
}

# IAM role for AppSync to invoke units Lambda
resource "aws_iam_role" "appsync_units_lambda_role" {
  name = "${var.project}-appsync-units-lambda-role"

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

# IAM policy for AppSync to invoke the units lambda
resource "aws_iam_role_policy" "appsync_units_lambda_policy" {
  name = "${var.project}-appsync-units-lambda-policy"
  role = aws_iam_role.appsync_units_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          data.aws_lambda_function.units_resolver.arn
        ]
      }
    ]
  })
}

# AppSync Data Source for units lambda
resource "aws_appsync_datasource" "units_lambda" {
  api_id           = aws_appsync_graphql_api.bff_api.id
  name             = "units_lambda"
  type             = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_units_lambda_role.arn

  lambda_config {
    function_arn = data.aws_lambda_function.units_resolver.arn
  }
}

# AppSync Resolver for getUnit query
resource "aws_appsync_resolver" "get_unit" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.units_lambda.name
  field       = "getUnit"
  type        = "Query"

  request_template  = local.units_request_template
  response_template = local.units_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for listUnits query
resource "aws_appsync_resolver" "list_units" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.units_lambda.name
  field       = "listUnits"
  type        = "Query"

  request_template  = local.units_request_template
  response_template = local.units_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for createUnit mutation
resource "aws_appsync_resolver" "create_unit" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.units_lambda.name
  field       = "createUnit"
  type        = "Mutation"

  request_template  = local.units_request_template
  response_template = local.units_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for updateUnit mutation
resource "aws_appsync_resolver" "update_unit" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.units_lambda.name
  field       = "updateUnit"
  type        = "Mutation"

  request_template  = local.units_request_template
  response_template = local.units_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for deleteUnit mutation
resource "aws_appsync_resolver" "delete_unit" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.units_lambda.name
  field       = "deleteUnit"
  type        = "Mutation"

  request_template  = local.units_request_template
  response_template = local.units_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}