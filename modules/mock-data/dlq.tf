# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

resource "aws_sqs_queue" "dlq_close" {
  name = "${var.application_name}-${var.tags["environment"]}-mock-data-auto-close-dlq"

  kms_master_key_id = var.kms_key_arn

  kms_data_key_reuse_period_seconds = 600

  message_retention_seconds = 604800 # 7 days

  tags = var.tags
}

resource "aws_sqs_queue" "dlq_hourly" {
  count = var.enable_hourly_tickets ? 1 : 0

  name = "${var.application_name}-${var.tags["environment"]}-mock-data-hourly-dlq"

  kms_master_key_id = var.kms_key_arn

  kms_data_key_reuse_period_seconds = 600

  message_retention_seconds = 604800 # 7 days

  tags = var.tags
}
