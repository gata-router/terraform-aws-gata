# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

resource "aws_sfn_state_machine" "summary" {
  name     = "${local.sfn_name}-summary"
  role_arn = aws_iam_role.sfn_summary.arn

  encryption_configuration {
    type       = "CUSTOMER_MANAGED_KMS_KEY"
    kms_key_id = var.kms_key_arn

    kms_data_key_reuse_period_seconds = 300
  }

  definition = templatefile("${path.module}/workflow-summary.asl.json", {
    aws_region = data.aws_region.current.name

    bedrock_model = data.aws_bedrock_foundation_model.summary.model_arn

    kms_key_arn = var.kms_key_arn

    lambda_ticket_comments_name = local.lambda_ticket_comments_name
    lambda_ticket_update_name   = local.lambda_ticket_update_name
    lambda_user_get_name        = local.lambda_user_get_name

    prompt = "'${trim(jsonencode(file("${path.module}/prompt.txt")), "\"")}'" # This is hacky AF but it works! It replaces the starting and end quotes.
  })

  logging_configuration {
    level = "ERROR"

    include_execution_data = true
    log_destination        = "${aws_cloudwatch_log_group.sfn_summary.arn}:*"
  }

  tracing_configuration {
    enabled = true
  }

  tags = var.tags
}

# trivy:ignore:AVD-AWS-0017 CWL SSE is adequate for the data being logged
resource "aws_cloudwatch_log_group" "sfn_summary" {
  name = "/aws/vendedlogs/states/${local.sfn_name}-summary"

  retention_in_days = 30

  tags = var.tags
}
