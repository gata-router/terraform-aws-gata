# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

output "lambda_function_arn" {
  description = "ARNs of the lambda function"
  value       = aws_lambda_function.this.arn
}

output "lambda_function_url" {
  description = "URL of the lambda function"
  value       = aws_lambda_function_url.this.function_url
}

output "lambda_role_arn" {
  description = "ARNs of the lambda role"
  value       = aws_iam_role.lambda.arn
}
