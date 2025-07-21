# Local values for account query resolver
locals {
  # Lambda function name for account resolver
  account_lambda_function_name = "sr-account-sandbox"

  # Request template for account resolver (passes through AppSync event structure)
  account_request_template = <<EOF
{
  "version": "2017-02-28",
  "operation": "Invoke",
  "payload": {
    "field": $util.toJson($context.info.fieldName),
    "arguments": $util.toJson($context.arguments.input),
    "identity": $util.toJson($context.identity),
    "request": $util.toJson($context.request),
    "source": $util.toJson($context.source),
    "info": {
      "fieldName": $util.toJson($context.info.fieldName),
      "parentTypeName": $util.toJson($context.info.parentTypeName),
      "variables": $util.toJson($context.info.variables)
    }
  }
}
EOF

  # Response template for account resolver
  account_response_template = <<EOF
$util.toJson($context.result)
EOF
}

# Data source for existing account lambda function
data "aws_lambda_function" "account_resolver" {
  function_name = local.account_lambda_function_name
}

# IAM role for AppSync to invoke account Lambda
resource "aws_iam_role" "appsync_account_lambda_role" {
  name = "${var.project}-appsync-account-lambda-role"

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

# IAM policy for AppSync to invoke the account lambda
resource "aws_iam_role_policy" "appsync_account_lambda_policy" {
  name = "${var.project}-appsync-account-lambda-policy"
  role = aws_iam_role.appsync_account_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          data.aws_lambda_function.account_resolver.arn
        ]
      }
    ]
  })
}

# AppSync Data Source for account lambda
resource "aws_appsync_datasource" "account_lambda" {
  api_id           = aws_appsync_graphql_api.bff_api.id
  name             = "account_lambda"
  type             = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_account_lambda_role.arn

  lambda_config {
    function_arn = data.aws_lambda_function.account_resolver.arn
  }
}

# AppSync Resolver for getAccount query
resource "aws_appsync_resolver" "get_account" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.account_lambda.name
  field       = "getAccount"
  type        = "Query"

  request_template  = local.account_request_template
  response_template = local.account_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for listAccounts query
resource "aws_appsync_resolver" "list_accounts" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.account_lambda.name
  field       = "listAccounts"
  type        = "Query"

  request_template  = local.account_request_template
  response_template = local.account_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for createAccount mutation
resource "aws_appsync_resolver" "create_account" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.account_lambda.name
  field       = "createAccount"
  type        = "Mutation"

  request_template  = local.account_request_template
  response_template = local.account_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for updateAccount mutation
resource "aws_appsync_resolver" "update_account" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.account_lambda.name
  field       = "updateAccount"
  type        = "Mutation"

  request_template  = local.account_request_template
  response_template = local.account_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for deleteAccount mutation
resource "aws_appsync_resolver" "delete_account" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.account_lambda.name
  field       = "deleteAccount"
  type        = "Mutation"

  request_template  = local.account_request_template
  response_template = local.account_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}
