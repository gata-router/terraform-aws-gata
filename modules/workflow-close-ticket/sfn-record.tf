# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

resource "aws_sfn_state_machine" "record" {
  name     = "${local.sfn_name}-record"
  role_arn = aws_iam_role.sfn_record.arn

  encryption_configuration {
    type       = "CUSTOMER_MANAGED_KMS_KEY"
    kms_key_id = var.kms_key_arn

    kms_data_key_reuse_period_seconds = 300
  }

  definition = templatefile("${path.module}/workflow-record.asl.json", {
    db_cluster_arn = var.db_cluster_arn
    db_secret_arn  = var.db_secret_arn

    kms_key_arn = var.kms_key_arn

    lambda_ticket_update_arn = var.lambda_ticket_update

    sfn_ticket_data_arn = local.sfn_ticket_data_arn

    ssm_param_group_mappings = local.ssm_params.group_mappings.name
  })

  logging_configuration {
    level = "ERROR"

    include_execution_data = true
    log_destination        = "${aws_cloudwatch_log_group.sfn_record.arn}:*"
  }

  tracing_configuration {
    enabled = true
  }

  tags = var.tags
}

# trivy:ignore:AVD-AWS-0017 CWL SSE is adequate for the data being logged
resource "aws_cloudwatch_log_group" "sfn_record" {
  name = "/aws/vendedlogs/states/${local.sfn_name}-record"

  retention_in_days = 30

  tags = var.tags
}
