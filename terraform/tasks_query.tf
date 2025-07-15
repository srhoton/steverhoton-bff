# Local values for tasks query resolver
locals {
  # Lambda function name for tasks resolver  
  tasks_lambda_function_name = "maintenance-task-dev-lambda"

  # Request template for tasks resolver
  tasks_request_template = <<EOF
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

  # Response template for tasks resolver
  tasks_response_template = <<EOF
$util.toJson($context.result)
EOF
}

# Data source for existing tasks lambda function
data "aws_lambda_function" "tasks_resolver" {
  function_name = local.tasks_lambda_function_name
}

# IAM policy for AppSync to invoke tasks lambda
resource "aws_iam_role_policy" "appsync_tasks_lambda_policy" {
  name = "steverhoton-bff-appsync-tasks-lambda-policy"
  role = aws_iam_role.appsync_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = data.aws_lambda_function.tasks_resolver.arn
      }
    ]
  })
}

# AppSync data source for tasks lambda
resource "aws_appsync_datasource" "tasks_lambda" {
  api_id           = aws_appsync_graphql_api.bff_api.id
  name             = "tasks_lambda"
  service_role_arn = aws_iam_role.appsync_lambda_role.arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = data.aws_lambda_function.tasks_resolver.arn
  }

  depends_on = [aws_iam_role_policy.appsync_tasks_lambda_policy]
}

# AppSync resolvers for tasks operations

# Query resolvers
resource "aws_appsync_resolver" "get_task" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  field       = "getTask"
  type        = "Query"
  data_source = aws_appsync_datasource.tasks_lambda.name

  request_template  = local.tasks_request_template
  response_template = local.tasks_response_template
}

resource "aws_appsync_resolver" "list_tasks" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  field       = "listTasks"
  type        = "Query"
  data_source = aws_appsync_datasource.tasks_lambda.name

  request_template  = local.tasks_request_template
  response_template = local.tasks_response_template
}

# Mutation resolvers
resource "aws_appsync_resolver" "create_task" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  field       = "createTask"
  type        = "Mutation"
  data_source = aws_appsync_datasource.tasks_lambda.name

  request_template  = local.tasks_request_template
  response_template = local.tasks_response_template
}

resource "aws_appsync_resolver" "update_task" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  field       = "updateTask"
  type        = "Mutation"
  data_source = aws_appsync_datasource.tasks_lambda.name

  request_template  = local.tasks_request_template
  response_template = local.tasks_response_template
}

resource "aws_appsync_resolver" "delete_task" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  field       = "deleteTask"
  type        = "Mutation"
  data_source = aws_appsync_datasource.tasks_lambda.name

  request_template  = local.tasks_request_template
  response_template = local.tasks_response_template
}