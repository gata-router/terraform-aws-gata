# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

resource "aws_sfn_state_machine" "create" {
  name     = local.sfn_name
  role_arn = aws_iam_role.sfn_create_ticket.arn

  encryption_configuration {
    type       = "CUSTOMER_MANAGED_KMS_KEY"
    kms_key_id = var.kms_key_arn

    kms_data_key_reuse_period_seconds = 300
  }

  definition = templatefile("${path.module}/workflow-new-ticket.asl.json", {
    bedrock_model = data.aws_bedrock_foundation_model.nova_pro.model_arn

    config_bucket_name = var.config_bucket_name

    dlq_arn = aws_sqs_queue.dlq_close.arn

    enable_hourly_tickets = var.enable_hourly_tickets

    kms_key_arn = var.kms_key_arn

    lambda_ticket_create_name = var.lambda_ticket_create
    lambda_ticket_update_arn  = local.lambda_ticket_update_arn

    prompt = "'${trim(jsonencode(file("${path.module}/prompt.txt")), "\"")}'"

    schedule_role_arn = aws_iam_role.close_scheduler.arn
  })

  logging_configuration {
    level = "ALL"

    include_execution_data = true

    log_destination = "${aws_cloudwatch_log_group.sfn_create.arn}:*"
  }

  tracing_configuration {
    enabled = true
  }

  tags = var.tags
}

# trivy:ignore:AVD-AWS-0017 CWL SSE is adequate for the data being logged
resource "aws_cloudwatch_log_group" "sfn_create" {
  name = "/aws/vendedlogs/states/${local.sfn_name}"

  retention_in_days = 30

  tags = var.tags
}
