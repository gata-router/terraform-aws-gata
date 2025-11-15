# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

output "role_arn" {
  value = aws_iam_role.github_actions.arn
}

output "role_name" {
  value = aws_iam_role.github_actions.name
}
