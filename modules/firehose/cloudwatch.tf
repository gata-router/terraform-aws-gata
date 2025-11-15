# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

#trivy:ignore:avd-aws-0017 Not logging sensitive data, CWL-SSE is adequate.
resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/kinesisfirehose/${local.firehose_stream_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_stream" "firehose_s3_delivery" {
  name = "S3Delivery"

  log_group_name = aws_cloudwatch_log_group.firehose.name
}
