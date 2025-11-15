# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_bedrock_foundation_model" "priority" {
  model_id = "amazon.nova-micro-v1:0"
}
