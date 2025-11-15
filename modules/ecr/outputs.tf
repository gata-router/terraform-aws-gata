# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

output "image_url" {
  description = "Full URL of the ECR image including tag or digest"
  value       = var.image_tag == null ? data.aws_ecr_image.this[0].image_uri : "${aws_ecr_repository.this.repository_url}${var.image_tag}"
}

output "repo_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.this.arn
}

output "repo_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.this.repository_url
}
