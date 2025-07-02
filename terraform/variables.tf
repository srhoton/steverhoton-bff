variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "steverhoton-bff"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "domain_name" {
  description = "Base domain name"
  type        = string
  default     = "steverhoton.com"

  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.domain_name))
    error_message = "Must be a valid domain name."
  }
}

variable "bff_subdomain" {
  description = "Subdomain for the BFF AppSync endpoint"
  type        = string
  default     = "bff"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.bff_subdomain))
    error_message = "Subdomain must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "cognito_user_pool_id" {
  description = "ID of the existing Cognito User Pool (if known, takes precedence over name)"
  type        = string
  default     = "us-east-1_plhb9FhBb"
}

variable "api_response_message" {
  description = "Message to return from the authenticated API endpoint"
  type        = string
  default     = "Hello from authenticated BFF endpoint!"
}

variable "graphql_query_name" {
  description = "Name of the GraphQL query for the authenticated endpoint"
  type        = string
  default     = "validateAuthn"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]*$", var.graphql_query_name))
    error_message = "GraphQL query name must start with a letter and contain only letters and numbers."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_logging" {
  description = "Enable CloudWatch logging for AppSync"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}
