# Get the existing Route53 hosted zone for the domain
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Get current AWS region information
data "aws_region" "current" {}

# Get specific Cognito User Pool details
data "aws_cognito_user_pool" "auth" {
  user_pool_id = var.cognito_user_pool_id
}