# modules/identity/outputs.tf

output "user_pool_id" {
  value = aws_cognito_user_pool.pool.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "user_pool_domain" {
  value = aws_cognito_user_pool_domain.main.domain
}

output "issuer_url" {
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.pool.id}"
  description = "The OIDC issuer URL for backend token validation"
}