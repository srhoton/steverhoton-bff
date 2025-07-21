# Local values for actions query resolver
locals {
  # Lambda function name for actions resolver
  actions_lambda_function_name = "sr-action-sandbox"

  # Request template for actions resolver (passes through AppSync event structure)
  actions_request_template = <<EOF
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

  # Response template for actions resolver
  actions_response_template = <<EOF
$util.toJson($context.result)
EOF
}

# Data source for existing actions lambda function
data "aws_lambda_function" "actions_resolver" {
  function_name = local.actions_lambda_function_name
}

# IAM policy for AppSync to invoke the actions lambda
resource "aws_iam_role_policy" "appsync_actions_lambda_policy" {
  name = "${var.project}-appsync-actions-lambda-policy"
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
          data.aws_lambda_function.actions_resolver.arn
        ]
      }
    ]
  })
}

# AppSync Data Source for actions lambda
resource "aws_appsync_datasource" "actions_lambda" {
  api_id           = aws_appsync_graphql_api.bff_api.id
  name             = "actions_lambda"
  type             = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_lambda_role.arn

  lambda_config {
    function_arn = data.aws_lambda_function.actions_resolver.arn
  }
}

# AppSync Resolver for getActionJob query
resource "aws_appsync_resolver" "get_action_job" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.actions_lambda.name
  field       = "getActionJob"
  type        = "Query"

  request_template  = local.actions_request_template
  response_template = local.actions_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for listActionJobs query
resource "aws_appsync_resolver" "list_action_jobs" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.actions_lambda.name
  field       = "listActionJobs"
  type        = "Query"

  request_template  = local.actions_request_template
  response_template = local.actions_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for listActionJobsByUnit query
resource "aws_appsync_resolver" "list_action_jobs_by_unit" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.actions_lambda.name
  field       = "listActionJobsByUnit"
  type        = "Query"

  request_template  = local.actions_request_template
  response_template = local.actions_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for createActionJob mutation
resource "aws_appsync_resolver" "create_action_job" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.actions_lambda.name
  field       = "createActionJob"
  type        = "Mutation"

  request_template  = local.actions_request_template
  response_template = local.actions_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for updateActionJob mutation
resource "aws_appsync_resolver" "update_action_job" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.actions_lambda.name
  field       = "updateActionJob"
  type        = "Mutation"

  request_template  = local.actions_request_template
  response_template = local.actions_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for deleteActionJob mutation
resource "aws_appsync_resolver" "delete_action_job" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.actions_lambda.name
  field       = "deleteActionJob"
  type        = "Mutation"

  request_template  = local.actions_request_template
  response_template = local.actions_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}
