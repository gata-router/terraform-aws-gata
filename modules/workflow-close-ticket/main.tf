# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_bedrock_foundation_model" "summary" {
  model_id = "amazon.nova-lite-v1:0"
}

data "aws_lambda_function" "ticket_update" {
  function_name = var.lambda_ticket_update
}
