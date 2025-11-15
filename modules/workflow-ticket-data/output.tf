# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

output "sfn_arn" {
  description = "ARN of the Step Function"
  value       = aws_sfn_state_machine.this.arn
}

output "sfn_name" {
  description = "Name of the Step Function"
  value       = aws_sfn_state_machine.this.name
}
