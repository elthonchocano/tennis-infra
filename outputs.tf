output "backend_api_url" {
  value       = aws_apigatewayv2_stage.stage.invoke_url
  description = "The HTTP API Gateway URL to be configured as VITE_API_URL in the frontend"
}

output "frontend_url" {
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
  description = "The public global URL of your deployed React application"
}

output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.pool.id
  description = "The AWS Cognito User Pool ID"
}