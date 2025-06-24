# Get the existing Route53 hosted zone for the domain
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Get current AWS account and region information
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Get specific Cognito User Pool details
data "aws_cognito_user_pool" "auth" {
  user_pool_id = var.cognito_user_pool_id
}

# Get availability zones for the current region
data "aws_availability_zones" "available" {
  state = "available"
}