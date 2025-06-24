# AppSync BFF Terraform Configuration

This Terraform configuration creates an AWS AppSync GraphQL API that serves as a Backend-for-Frontend (BFF) service with Cognito User Pool authentication.

## Architecture

- **AppSync GraphQL API**: Main BFF endpoint with Cognito User Pool authentication
- **Custom Domain**: `bff.steverhoton.com` with SSL certificate
- **Authentication**: Integrated with existing Cognito User Pool (`steverhoton-auth-prod-main-user-pool`)
- **DNS**: Route53 records for the custom domain
- **Logging**: CloudWatch logs for API requests (optional)

## Prerequisites

1. **Existing AWS Infrastructure**:
   - Cognito User Pool: `steverhoton-auth-prod-main-user-pool` (ID: `us-east-1_plhb9FhBb`)
   - Route53 hosted zone for `steverhoton.com`

2. **Tools**:
   - AWS CLI configured with appropriate permissions
   - Terraform >= 1.5 installed

3. **AWS Permissions Required**:
   - Route53: Create/modify DNS records
   - ACM: Create/validate SSL certificates
   - AppSync: Create GraphQL APIs, resolvers, and data sources
   - Cognito: Read User Pool information
   - CloudWatch: Create log groups (if logging enabled)
   - IAM: Create roles and policies

## Configuration Variables

### Required Variables
- `domain_name`: Base domain name (default: `steverhoton.com`)
- `cognito_user_pool_id`: ID of existing Cognito User Pool (default: `us-east-1_plhb9FhBb`)
- `cognito_user_pool_name`: Name of existing Cognito User Pool (default: `steverhoton-auth-prod-main-user-pool`)

### Optional Variables
- `aws_region`: AWS region (default: `us-east-1`)
- `project`: Project name for resource naming (default: `steverhoton-bff`)
- `environment`: Environment name (default: `prod`)
- `bff_subdomain`: Subdomain for BFF API (default: `bff`)
- `graphql_query_name`: GraphQL query name (default: `validateAuthn`)
- `api_response_message`: Authentication success message
- `enable_logging`: Enable CloudWatch logging (default: `true`)
- `log_retention_days`: Log retention period (default: `14`)

## Deployment

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Review Configuration (Optional)
Create `terraform.tfvars` to customize variables:
```hcl
# terraform.tfvars
aws_region = "us-east-1"
environment = "prod"
cognito_user_pool_name = "steverhoton-auth-prod-main-user-pool"
api_response_message = "Successfully authenticated with BFF!"
```

### 3. Plan Deployment
```bash
terraform plan
```

### 4. Apply Configuration
```bash
terraform apply
```

### 5. Verify Deployment
After successful deployment, the API will be available at:
- **GraphQL Endpoint**: `https://bff.steverhoton.com/graphql`
- **AppSync Console**: Check AWS AppSync console for the API

## API Usage

### Authentication
All requests must include a valid Cognito User Pool JWT token in the `Authorization` header:
```
Authorization: Bearer <JWT_TOKEN>
```

### GraphQL Query
```graphql
query {
  validateAuthn {
    message
    timestamp
    user
    success
  }
}
```

### Sample Request (cURL)
```bash
curl -X POST https://bff.steverhoton.com/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "query": "query { validateAuthn { message timestamp user success } }"
  }'
```

### Sample Response
```json
{
  "data": {
    "validateAuthn": {
      "message": "Hello, authenticated user! You have successfully accessed the BFF.",
      "timestamp": "2024-01-15T10:30:00.000Z",
      "user": "username@example.com",
      "success": true
    }
  }
}
```

### Unauthenticated Response
```json
{
  "errors": [
    {
      "errorType": "UnauthorizedException",
      "message": "Unable to parse JWT token."
    }
  ]
}
```

## Outputs

After deployment, Terraform provides these outputs:
- `appsync_graphql_api_id`: AppSync API ID
- `appsync_graphql_api_arn`: AppSync API ARN
- `bff_domain_name`: Custom domain name
- `bff_graphql_url`: Full GraphQL endpoint URL
- `certificate_arn`: SSL certificate ARN
- `cognito_user_pool_id`: Cognito User Pool ID used
- `sample_query`: Sample GraphQL query for testing

## Monitoring and Troubleshooting

### CloudWatch Logs
If logging is enabled, check CloudWatch logs:
- **Log Group**: `/aws/appsync/apis/steverhoton-bff-bff`
- **Log Level**: ALL (includes request/response data)

### Common Issues

1. **Certificate Validation Timeout**:
   - Ensure Route53 hosted zone is properly configured
   - Check DNS propagation

2. **Cognito User Pool Not Found**:
   - Verify `cognito_user_pool_name` variable
   - Ensure User Pool exists in the same AWS account/region

3. **Authentication Failures**:
   - Verify JWT token is valid and not expired
   - Check Cognito User Pool configuration
   - Ensure user is confirmed in the User Pool

### Validation Commands
```bash
# Validate Terraform configuration
terraform validate

# Format Terraform files
terraform fmt

# Check current state
terraform show

# Plan changes
terraform plan
```

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

**Note**: This will remove all resources including the custom domain and SSL certificate.

## Security Considerations

- JWT tokens are validated by Cognito User Pool
- SSL/TLS encryption in transit via HTTPS
- CloudWatch logs may contain sensitive data (review retention settings)
- IAM roles follow principle of least privilege

## Future Enhancements

This configuration provides a foundation for:
- Adding Lambda function resolvers
- Implementing additional GraphQL operations
- Adding data sources (DynamoDB, RDS, etc.)
- Implementing subscription support
- Adding API rate limiting