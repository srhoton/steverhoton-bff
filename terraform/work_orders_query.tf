# Local values for work orders query resolver
locals {
  # Lambda function name for work orders resolver
  work_orders_lambda_function_name = "work-order-dev-lambda"
  # Request template for work orders resolver
  work_orders_request_template = <<EOF
{
  "version": "2017-02-28",
  "operation": "Invoke",
  "payload": {
    "info": {
      "fieldName": $util.toJson($context.info.fieldName)
    },
    "arguments": $util.toJson($context.arguments),
    "identity": $util.toJson($context.identity),
    "request": $util.toJson($context.request)
  }
}
EOF


  # Response template for work orders resolver - Lambda returns exact enum values
  work_orders_response_template = <<EOF
## Lambda returns exact GraphQL enum values: draft, pending, inProgress, completed
$util.toJson($context.result)

EOF
}

# Data source for existing work orders lambda function
data "aws_lambda_function" "work_orders_resolver" {
  function_name = local.work_orders_lambda_function_name
}

# IAM policy for AppSync to invoke work orders lambda
resource "aws_iam_role_policy" "appsync_work_orders_lambda_policy" {
  name = "steverhoton-bff-appsync-work-orders-lambda-policy"
  role = aws_iam_role.appsync_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = data.aws_lambda_function.work_orders_resolver.arn
      }
    ]
  })
}

# AppSync data source for work orders lambda
resource "aws_appsync_datasource" "work_orders_lambda" {
  api_id           = aws_appsync_graphql_api.bff_api.id
  name             = "work_orders_lambda"
  service_role_arn = aws_iam_role.appsync_lambda_role.arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = data.aws_lambda_function.work_orders_resolver.arn
  }

  depends_on = [aws_iam_role_policy.appsync_work_orders_lambda_policy]
}

# AppSync resolvers for work orders operations

# Query resolvers
resource "aws_appsync_resolver" "get_work_order" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  field       = "getWorkOrder"
  type        = "Query"
  data_source = aws_appsync_datasource.work_orders_lambda.name

  request_template  = local.work_orders_request_template
  response_template = local.work_orders_response_template
}

resource "aws_appsync_resolver" "list_work_orders" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  field       = "listWorkOrders"
  type        = "Query"
  data_source = aws_appsync_datasource.work_orders_lambda.name

  request_template  = local.work_orders_request_template
  response_template = local.work_orders_response_template
}

resource "aws_appsync_resolver" "get_work_orders_by_unit_id" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  field       = "getWorkOrdersByUnitId"
  type        = "Query"
  data_source = aws_appsync_datasource.work_orders_lambda.name

  request_template  = local.work_orders_request_template
  response_template = local.work_orders_response_template
}

# Mutation resolvers
resource "aws_appsync_resolver" "create_work_order" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  field       = "createWorkOrder"
  type        = "Mutation"
  data_source = aws_appsync_datasource.work_orders_lambda.name

  request_template  = local.work_orders_request_template
  response_template = local.work_orders_response_template
}

resource "aws_appsync_resolver" "update_work_order" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  field       = "updateWorkOrder"
  type        = "Mutation"
  data_source = aws_appsync_datasource.work_orders_lambda.name

  request_template  = local.work_orders_request_template
  response_template = local.work_orders_response_template
}

resource "aws_appsync_resolver" "delete_work_order" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  field       = "deleteWorkOrder"
  type        = "Mutation"
  data_source = aws_appsync_datasource.work_orders_lambda.name

  request_template  = local.work_orders_request_template
  response_template = local.work_orders_response_template
}