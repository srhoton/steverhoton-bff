# Local values for labor lines query resolver
locals {
  # Lambda function name for labor lines resolver
  labor_lines_lambda_function_name = "labor-lines-prod-labor-lines-handler"

  # Request template for labor lines resolver (matches labor lines lambda AppSyncEvent structure)
  labor_lines_request_template = <<EOF
{
  "version": "2017-02-28",
  "operation": "Invoke",
  "payload": {
    "typeName": $util.toJson($context.info.parentTypeName),
    "fieldName": $util.toJson($context.info.fieldName),
    "arguments": $util.toJson($context.arguments),
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

  # Response template for labor lines resolver
  labor_lines_response_template = <<EOF
$util.toJson($context.result)
EOF
}

# Data source for existing labor lines lambda function
data "aws_lambda_function" "labor_lines_resolver" {
  function_name = local.labor_lines_lambda_function_name
}

# IAM policy for AppSync to invoke the labor lines lambda
resource "aws_iam_role_policy" "appsync_labor_lines_lambda_policy" {
  name = "${var.project}-appsync-labor-lines-lambda-policy"
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
          data.aws_lambda_function.labor_lines_resolver.arn
        ]
      }
    ]
  })
}

# AppSync Data Source for labor lines lambda
resource "aws_appsync_datasource" "labor_lines_lambda" {
  api_id           = aws_appsync_graphql_api.bff_api.id
  name             = "labor_lines_lambda"
  type             = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_lambda_role.arn

  lambda_config {
    function_arn = data.aws_lambda_function.labor_lines_resolver.arn
  }
}

# AppSync Resolver for getLaborLine query
resource "aws_appsync_resolver" "get_labor_line" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.labor_lines_lambda.name
  field       = "getLaborLine"
  type        = "Query"

  request_template  = local.labor_lines_request_template
  response_template = local.labor_lines_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for listLaborLines query
resource "aws_appsync_resolver" "list_labor_lines" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.labor_lines_lambda.name
  field       = "listLaborLines"
  type        = "Query"

  request_template  = local.labor_lines_request_template
  response_template = local.labor_lines_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for createLaborLine mutation
resource "aws_appsync_resolver" "create_labor_line" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.labor_lines_lambda.name
  field       = "createLaborLine"
  type        = "Mutation"

  request_template  = local.labor_lines_request_template
  response_template = local.labor_lines_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for updateLaborLine mutation
resource "aws_appsync_resolver" "update_labor_line" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.labor_lines_lambda.name
  field       = "updateLaborLine"
  type        = "Mutation"

  request_template  = local.labor_lines_request_template
  response_template = local.labor_lines_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for deleteLaborLine mutation
resource "aws_appsync_resolver" "delete_labor_line" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.labor_lines_lambda.name
  field       = "deleteLaborLine"
  type        = "Mutation"

  request_template  = local.labor_lines_request_template
  response_template = local.labor_lines_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}