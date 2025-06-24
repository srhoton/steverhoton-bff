output "appsync_graphql_api_id" {
  description = "ID of the AppSync GraphQL API"
  value       = aws_appsync_graphql_api.bff_api.id
}

output "appsync_graphql_api_arn" {
  description = "ARN of the AppSync GraphQL API"
  value       = aws_appsync_graphql_api.bff_api.arn
}

output "appsync_graphql_api_uris" {
  description = "Map of URIs associated with the AppSync GraphQL API"
  value       = aws_appsync_graphql_api.bff_api.uris
}

output "bff_domain_name" {
  description = "Domain name for the BFF AppSync endpoint"
  value       = local.bff_domain_name
}

output "bff_graphql_url" {
  description = "GraphQL endpoint URL for the BFF API"
  value       = "https://${local.bff_domain_name}/graphql"
}

output "certificate_arn" {
  description = "ARN of the SSL certificate for the BFF domain"
  value       = aws_acm_certificate.bff_cert.arn
}

output "certificate_status" {
  description = "Status of the SSL certificate"
  value       = aws_acm_certificate.bff_cert.status
}

output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool used for authentication"
  value       = data.aws_cognito_user_pool.auth.id
}

output "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool used for authentication"
  value       = data.aws_cognito_user_pool.auth.arn
}

output "cognito_user_pool_name" {
  description = "Name of the Cognito User Pool used for authentication"
  value       = data.aws_cognito_user_pool.auth.name
}

output "route53_zone_id" {
  description = "ID of the Route53 hosted zone"
  value       = data.aws_route53_zone.main.zone_id
}

output "route53_zone_name" {
  description = "Name of the Route53 hosted zone"
  value       = data.aws_route53_zone.main.name
}

output "appsync_domain_name" {
  description = "AppSync domain name resource information"
  value = {
    domain_name         = aws_appsync_domain_name.bff_domain.domain_name
    appsync_domain_name = aws_appsync_domain_name.bff_domain.appsync_domain_name
    hosted_zone_id      = aws_appsync_domain_name.bff_domain.hosted_zone_id
  }
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for AppSync (if logging enabled)"
  value       = var.enable_logging ? aws_cloudwatch_log_group.appsync_logs[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for AppSync (if logging enabled)"
  value       = var.enable_logging ? aws_cloudwatch_log_group.appsync_logs[0].arn : null
}

output "graphql_query_name" {
  description = "Name of the GraphQL query for authenticated requests"
  value       = var.graphql_query_name
}

output "sample_query" {
  description = "Sample GraphQL query to test the authenticated endpoint"
  value = jsonencode({
    query = "query { ${var.graphql_query_name} { message timestamp user success } }"
  })
}