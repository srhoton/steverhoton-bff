# Local values for common configuration
locals {
  bff_domain_name = "${var.bff_subdomain}.${var.domain_name}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Owner       = "steverhoton"
  })

  graphql_schema = join("\n\n", [
    file("${path.module}/authenticated_query.graphql"),
    file("${path.module}/contact_query.graphql"),
    file("${path.module}/location_query.graphql"),
    file("${path.module}/account_query.graphql"),
    file("${path.module}/units_query.graphql"),
    file("${path.module}/parts_query.graphql"),
    file("${path.module}/actions_query.graphql"),
    file("${path.module}/events_query.graphql"),
    file("${path.module}/labor_lines_query.graphql"),
    file("${path.module}/tasks_query.graphql"),
    file("${path.module}/work_orders_query.graphql")
  ])
}

# SSL Certificate for bff.steverhoton.com (must be in us-east-1 for AppSync)
resource "aws_acm_certificate" "bff_cert" {
  provider          = aws.us_east_1
  domain_name       = local.bff_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-bff-certificate"
  })
}

# DNS validation records for the certificate
resource "aws_route53_record" "bff_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.bff_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id

  depends_on = [aws_acm_certificate.bff_cert]
}

# Certificate validation
resource "aws_acm_certificate_validation" "bff_cert" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.bff_cert.arn
  validation_record_fqdns = [
    for record in aws_route53_record.bff_cert_validation : record.fqdn
  ]

  timeouts {
    create = "5m"
  }
}

# CloudWatch Log Group for AppSync
resource "aws_cloudwatch_log_group" "appsync_logs" {
  count             = var.enable_logging ? 1 : 0
  name              = "/aws/appsync/apis/${var.project}-bff"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project}-appsync-logs"
  })
}

# IAM role for AppSync logging
resource "aws_iam_role" "appsync_logs" {
  count = var.enable_logging ? 1 : 0
  name  = "${var.project}-appsync-logs-role"

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

# IAM policy for AppSync logging
resource "aws_iam_role_policy" "appsync_logs" {
  count = var.enable_logging ? 1 : 0
  name  = "${var.project}-appsync-logs-policy"
  role  = aws_iam_role.appsync_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          aws_cloudwatch_log_group.appsync_logs[0].arn,
          "${aws_cloudwatch_log_group.appsync_logs[0].arn}:*"
        ]
      }
    ]
  })
}

# AppSync GraphQL API
resource "aws_appsync_graphql_api" "bff_api" {
  name                = "${var.project}-bff-api"
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  schema              = local.graphql_schema

  user_pool_config {
    default_action = "ALLOW"
    user_pool_id   = data.aws_cognito_user_pool.auth.id
    aws_region     = data.aws_region.current.name
  }

  dynamic "log_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      cloudwatch_logs_role_arn = aws_iam_role.appsync_logs[0].arn
      field_log_level          = "ALL"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-bff-api"
  })

  depends_on = [aws_iam_role_policy.appsync_logs]
}

# Custom domain name for AppSync
resource "aws_appsync_domain_name" "bff_domain" {
  domain_name     = local.bff_domain_name
  certificate_arn = aws_acm_certificate_validation.bff_cert.certificate_arn

  depends_on = [aws_acm_certificate_validation.bff_cert]
}

# Associate domain with AppSync API
resource "aws_appsync_domain_name_api_association" "bff_domain" {
  api_id      = aws_appsync_graphql_api.bff_api.id
  domain_name = aws_appsync_domain_name.bff_domain.domain_name
}

# Route53 record for BFF subdomain
resource "aws_route53_record" "bff_domain" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.bff_domain_name
  type    = "A"

  alias {
    name                   = aws_appsync_domain_name.bff_domain.appsync_domain_name
    zone_id                = aws_appsync_domain_name.bff_domain.hosted_zone_id
    evaluate_target_health = true
  }

  depends_on = [aws_appsync_domain_name_api_association.bff_domain]
}