# Local values for parts query resolver
locals {
  # Lambda function name for parts resolver
  parts_lambda_function_name = "sr-part-sandbox"

  # Request template for parts resolver (passes through AppSync event structure)
  parts_request_template = <<EOF
{
  "version": "2017-02-28",
  "operation": "Invoke",
  "payload": {
    "arguments": $util.toJson($context.arguments),
    "identity": $util.toJson($context.identity),
    "request": $util.toJson($context.request),
    "info": {
      "fieldName": $util.toJson($context.info.fieldName),
      "parentTypeName": $util.toJson($context.info.parentTypeName),
      "selectionSetGraphQL": $util.toJson($context.info.selectionSetGraphQL),
      "selectionSetList": $util.toJson($context.info.selectionSetList),
      "variables": $util.toJson($context.info.variables)
    },
    "prev": $util.toJson($context.prev)
  }
}
EOF

  # Response template for parts resolver
  parts_response_template = <<EOF
$util.toJson($context.result)
EOF
}

# Data source for existing parts lambda function
data "aws_lambda_function" "parts_resolver" {
  function_name = local.parts_lambda_function_name
}

# IAM policy for AppSync to invoke the parts lambda
resource "aws_iam_role_policy" "appsync_parts_lambda_policy" {
  name = "${var.project}-appsync-parts-lambda-policy"
  role = aws_iam_role.appsync_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          data.aws_lambda_function.parts_resolver.arn
        ]
      }
    ]
  })
}

# AppSync Data Source for parts lambda
resource "aws_appsync_datasource" "parts_lambda" {
  api_id           = aws_appsync_graphql_api.bff_api.id
  name             = "parts_lambda"
  type             = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_lambda_role.arn

  lambda_config {
    function_arn = data.aws_lambda_function.parts_resolver.arn
  }
}

# AppSync Resolver for getPart query
resource "aws_appsync_resolver" "get_part" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.parts_lambda.name
  field       = "getPart"
  type        = "Query"

  request_template  = local.parts_request_template
  response_template = local.parts_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for listParts query
resource "aws_appsync_resolver" "list_parts" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.parts_lambda.name
  field       = "listParts"
  type        = "Query"

  request_template  = local.parts_request_template
  response_template = local.parts_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for getPartsByLocation query
resource "aws_appsync_resolver" "get_parts_by_location" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.parts_lambda.name
  field       = "getPartsByLocation"
  type        = "Query"

  request_template  = local.parts_request_template
  response_template = local.parts_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for getPartsByUnit query
resource "aws_appsync_resolver" "get_parts_by_unit" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.parts_lambda.name
  field       = "getPartsByUnit"
  type        = "Query"

  request_template  = local.parts_request_template
  response_template = local.parts_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for createPart mutation
resource "aws_appsync_resolver" "create_part" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.parts_lambda.name
  field       = "createPart"
  type        = "Mutation"

  request_template  = local.parts_request_template
  response_template = local.parts_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for updatePart mutation
resource "aws_appsync_resolver" "update_part" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.parts_lambda.name
  field       = "updatePart"
  type        = "Mutation"

  request_template  = local.parts_request_template
  response_template = local.parts_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for deletePart mutation
resource "aws_appsync_resolver" "delete_part" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.parts_lambda.name
  field       = "deletePart"
  type        = "Mutation"

  request_template  = local.parts_request_template
  response_template = local.parts_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}
