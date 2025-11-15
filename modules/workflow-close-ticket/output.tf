# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

output "step_function_record_arn" {
  description = "ARN of the data recording Step Function"
  value       = aws_sfn_state_machine.record.arn
}

output "step_function_summary_arn" {
  description = "ARN of the summary Step Function"
  value       = aws_sfn_state_machine.summary.arn
}
