# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

output "stream_name" {
  description = "Name of the Kinesis Data Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.events.name
}

output "stream_arn" {
  description = "ARN of the Kinesis Data Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.events.arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.firehose.name
}

output "firehose_role_arn" {
  description = "ARN of the Firehose service role"
  value       = aws_iam_role.firehose.arn
}
