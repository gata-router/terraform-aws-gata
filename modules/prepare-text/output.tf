# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

output "lambda_function" {
  description = "ARN of the lambda function"
  value       = aws_lambda_function.this.arn
}

output "lambda_role_arn" {
  description = "ARN of the lambda role"
  value       = aws_iam_role.lambda.arn
}
