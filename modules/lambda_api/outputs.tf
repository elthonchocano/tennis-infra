output "api_endpoint" { value = aws_apigatewayv2_api.http_api.api_endpoint }
output "lambda_arn" { value = aws_lambda_function.api.arn }
output "lambda_name" { value = aws_lambda_function.api.function_name }
output "api_invoke_url" { value = aws_apigatewayv2_stage.stage.invoke_url }
output "api_id" { value = aws_apigatewayv2_api.http_api.id }