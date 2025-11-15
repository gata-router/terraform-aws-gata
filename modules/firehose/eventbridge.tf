# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

resource "aws_cloudwatch_event_rule" "firehose" {
  name        = "all-to-firehose-${var.tags["environment"]}"
  description = "All events to Amazon Data Firehose"

  event_bus_name = var.eventbus
  state          = "ENABLED"

  event_pattern = jsonencode({
    source = ["zendesk.com"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "firehose" {
  event_bus_name = var.eventbus
  rule           = aws_cloudwatch_event_rule.firehose.name

  target_id = "firehose"
  arn       = aws_kinesis_firehose_delivery_stream.events.arn

  role_arn = aws_iam_role.eventbridge_firehose.arn
}
