# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

output "ecs_role_exec_name" {
  description = "Name of the IAM execution role for data prep ECS task"
  value       = aws_iam_role.data_prep_exec.name
}

output "ecs_role_task_name" {
  description = "Name of the IAM task role for data prep ECS task"
  value       = aws_iam_role.data_prep_task.name
}

output "security_group" {
  description = "ID of the security group used by the ECS task"
  value       = aws_security_group.this.id
}
