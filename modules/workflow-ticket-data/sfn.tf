# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

resource "aws_sfn_state_machine" "this" {
  name     = local.sfn_name
  role_arn = aws_iam_role.sfn_ticket_data.arn

  encryption_configuration {
    type       = "CUSTOMER_MANAGED_KMS_KEY"
    kms_key_id = var.kms_key_arn

    kms_data_key_reuse_period_seconds = 300
  }

  definition = templatefile("${path.module}/workflow.asl.json", {
    lambda_prepare_text_arn = var.lambda_prepare_text
    lambda_redact_arn       = var.lambda_redact
    lambda_ticket_get_arn   = var.lambda_ticket_get
    titan_embed_model_arn   = data.aws_bedrock_foundation_model.titan_embed.model_arn
  })

  logging_configuration {
    level = "ALL" # Provides the additional information we need for express workflows.

    include_execution_data = true
    log_destination        = "${aws_cloudwatch_log_group.sfn_new_ticket.arn}:*"
  }

  tracing_configuration {
    enabled = true
  }

  tags = var.tags
}

# trivy:ignore:AVD-AWS-0017 CWL SSE is adequate for the data being logged
resource "aws_cloudwatch_log_group" "sfn_new_ticket" {
  name = "/aws/vendedlogs/states/${local.sfn_name}"

  retention_in_days = 30

  tags = var.tags
}
