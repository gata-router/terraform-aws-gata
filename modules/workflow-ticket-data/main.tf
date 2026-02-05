# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

data "aws_bedrock_foundation_model" "titan_embed" {
  model_id = "amazon.titan-embed-text-v2:0"
}

data "aws_caller_identity" "current" {}
