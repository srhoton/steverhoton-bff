# Local values for events query resolver
locals {
  # Lambda function name for events resolver
  events_lambda_function_name = "steverhoton-events-handler-prod"

  # Request template for events resolver (passes through AppSync event structure)
  events_request_template = <<EOF
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

  # Response template for events resolver
  events_response_template = <<EOF
$util.toJson($context.result)
EOF
}

# Data source for existing events lambda function
data "aws_lambda_function" "events_resolver" {
  function_name = local.events_lambda_function_name
}

# IAM policy for AppSync to invoke the events lambda
resource "aws_iam_role_policy" "appsync_events_lambda_policy" {
  name = "${var.project}-appsync-events-lambda-policy"
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
          data.aws_lambda_function.events_resolver.arn
        ]
      }
    ]
  })
}

# AppSync Data Source for events lambda
resource "aws_appsync_datasource" "events_lambda" {
  api_id           = aws_appsync_graphql_api.bff_api.id
  name             = "events_lambda"
  type             = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_lambda_role.arn

  lambda_config {
    function_arn = data.aws_lambda_function.events_resolver.arn
  }
}

# AppSync Resolver for getEvent query
resource "aws_appsync_resolver" "get_event" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.events_lambda.name
  field       = "getEvent"
  type        = "Query"

  request_template  = local.events_request_template
  response_template = local.events_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for listEvents query
resource "aws_appsync_resolver" "list_events" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.events_lambda.name
  field       = "listEvents"
  type        = "Query"

  request_template  = local.events_request_template
  response_template = local.events_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for listEventsByUnit query
resource "aws_appsync_resolver" "list_events_by_unit" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.events_lambda.name
  field       = "listEventsByUnit"
  type        = "Query"

  request_template  = local.events_request_template
  response_template = local.events_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for listEventsByCategory query
resource "aws_appsync_resolver" "list_events_by_category" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.events_lambda.name
  field       = "listEventsByCategory"
  type        = "Query"

  request_template  = local.events_request_template
  response_template = local.events_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for listEventsByStatus query
resource "aws_appsync_resolver" "list_events_by_status" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.events_lambda.name
  field       = "listEventsByStatus"
  type        = "Query"

  request_template  = local.events_request_template
  response_template = local.events_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for createEvent mutation
resource "aws_appsync_resolver" "create_event" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.events_lambda.name
  field       = "createEvent"
  type        = "Mutation"

  request_template  = local.events_request_template
  response_template = local.events_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for updateEvent mutation
resource "aws_appsync_resolver" "update_event" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.events_lambda.name
  field       = "updateEvent"
  type        = "Mutation"

  request_template  = local.events_request_template
  response_template = local.events_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}

# AppSync Resolver for deleteEvent mutation
resource "aws_appsync_resolver" "delete_event" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.events_lambda.name
  field       = "deleteEvent"
  type        = "Mutation"

  request_template  = local.events_request_template
  response_template = local.events_response_template

  depends_on = [aws_appsync_graphql_api.bff_api]
}