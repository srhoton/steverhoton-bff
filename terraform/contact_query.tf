# Local values for contact query resolver
locals {
  # Lambda function name for contact resolver
  contact_lambda_function_name = "sr-contact-sandbox"

  # Request template for contact resolver (passes through AppSync event structure)
  contact_request_template = <<EOF
{
  "version": "2017-02-28",
  "operation": "Invoke",
  "payload": {
    "arguments": $util.toJson($context.arguments.input),
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

  # Response template for contact resolver
  contact_response_template = <<EOF
$util.toJson($context.result)
EOF
}

# Data source for existing contact lambda function
data "aws_lambda_function" "contact_resolver" {
  function_name = local.contact_lambda_function_name
}

# IAM role for AppSync to invoke Lambda
resource "aws_iam_role" "appsync_lambda_role" {
  name = "${var.project}-appsync-lambda-role"

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

# IAM policy for AppSync to invoke the contact lambda
resource "aws_iam_role_policy" "appsync_lambda_policy" {
  name = "${var.project}-appsync-lambda-policy"
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
          data.aws_lambda_function.contact_resolver.arn
        ]
      }
    ]
  })
}

# AppSync Data Source for contact lambda
resource "aws_appsync_datasource" "contact_lambda" {
  api_id           = aws_appsync_graphql_api.bff_api.id
  name             = "contact_lambda"
  type             = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_lambda_role.arn

  lambda_config {
    function_arn = data.aws_lambda_function.contact_resolver.arn
  }
}

# AppSync Resolver for getContact query
resource "aws_appsync_resolver" "get_contact" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.contact_lambda.name
  field       = "getContact"
  type        = "Query"

  request_template  = local.contact_request_template
  response_template = local.contact_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for listContacts query
resource "aws_appsync_resolver" "list_contacts" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.contact_lambda.name
  field       = "listContacts"
  type        = "Query"

  request_template  = local.contact_request_template
  response_template = local.contact_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for getContactByContactId query
resource "aws_appsync_resolver" "get_contact_by_contact_id" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.contact_lambda.name
  field       = "getContactByContactId"
  type        = "Query"

  request_template  = local.contact_request_template
  response_template = local.contact_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for createContact mutation
resource "aws_appsync_resolver" "create_contact" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.contact_lambda.name
  field       = "createContact"
  type        = "Mutation"

  request_template  = local.contact_request_template
  response_template = local.contact_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for updateContact mutation
resource "aws_appsync_resolver" "update_contact" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.contact_lambda.name
  field       = "updateContact"
  type        = "Mutation"

  request_template  = local.contact_request_template
  response_template = local.contact_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for deleteContact mutation
resource "aws_appsync_resolver" "delete_contact" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.contact_lambda.name
  field       = "deleteContact"
  type        = "Mutation"

  request_template  = local.contact_request_template
  response_template = local.contact_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}
