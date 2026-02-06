# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

resource "aws_sfn_state_machine" "this" {
  name     = local.sfn_name
  role_arn = aws_iam_role.sfn_new_ticket.arn

  encryption_configuration {
    type       = "CUSTOMER_MANAGED_KMS_KEY"
    kms_key_id = var.kms_key_arn

    kms_data_key_reuse_period_seconds = 300
  }

  definition = templatefile("${path.module}/workflow.asl.json", {
    db_cluster_arn = var.db_cluster_arn,
    db_secret_arn  = var.db_secret_arn,

    lambda_ticket_get_name    = split(":", provider::aws::arn_parse(var.lambda_ticket_get_arn).resource)[1],
    lambda_ticket_update_name = split(":", provider::aws::arn_parse(var.lambda_ticket_update_arn).resource)[1]
  })

  logging_configuration {
    level = "ALL"

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
