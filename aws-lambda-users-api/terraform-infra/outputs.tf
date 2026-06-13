output "api_base_url" {
  description = "Base URL of the HTTP API. Append /users etc."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "lambda_function_name" {
  value = aws_lambda_function.users_api.function_name
}

output "lambda_layer_arn" {
  value = aws_lambda_layer_version.pydantic.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.users.name
}
