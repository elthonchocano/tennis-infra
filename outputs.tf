output "backend_api_url" {
  value       = module.api_backend.api_invoke_url
  description = "The HTTP API Gateway URL to be configured as VITE_API_URL in the frontend"
}

output "frontend_url" {
  value       = "https://${module.frontend.cloudfront_domain_name}"
  description = "The public global URL of your deployed React application"
}

output "cognito_user_pool_id" {
  value       = module.identity.user_pool_id
  description = "The AWS Cognito User Pool ID"
}