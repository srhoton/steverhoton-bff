# Local values for authenticated query resolver
locals {
  # Request template for authenticated query resolver
  authenticated_query_request_template = <<EOF
{
  "version": "2017-02-28",
  "payload": {}
}
EOF

  # Response template for authenticated query resolver
  authenticated_query_response_template = <<EOF
{
  "message": "${var.api_response_message}",
  "timestamp": "$util.time.nowISO8601()",
  "user": "$context.identity.username",
  "success": true
}
EOF
}

# AppSync Data Source (None/Local) for authenticated query
resource "aws_appsync_datasource" "authenticated_query_none" {
  api_id = aws_appsync_graphql_api.bff_api.id
  name   = "authenticated_query_none"
  type   = "NONE"
}

# AppSync Resolver for the authenticated query
resource "aws_appsync_resolver" "authenticated_query" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  data_source = aws_appsync_datasource.authenticated_query_none.name
  field       = var.graphql_query_name
  type        = "Query"

  request_template  = local.authenticated_query_request_template
  response_template = local.authenticated_query_response_template
}