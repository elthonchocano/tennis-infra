output "frontend_url" {
  value       = "https://${module.frontend.cloudfront_domain_name}"
  description = "The public global URL of your deployed React application"
}

output "cognito_user_pool_id" {
  value       = module.identity.user_pool_id
  description = "The AWS Cognito User Pool ID"
}

output "pipeline_bucket_name" {
  value = module.cicd.pipeline_bucket_name
}

output "cognito_issuer_url" {
  value       = module.identity.issuer_url
  description = "Copy this URL into your backend provider's environment variables"
}
