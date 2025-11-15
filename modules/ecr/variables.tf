# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

variable "admin_role_arn" {
  description = "ARN of the IAM role to use for admin access"
  type        = string
}

variable "image_tag" {
  description = "Tag of the image to use. If not set, the value will be pulled from SSM Params."
  type        = string
}

variable "image_tag_param_name" {
  description = "Name of the SSM Parameter to use to get the image tag if image_tag is not set"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encryption at rest"
  type        = string
}

variable "name" {
  description = "The name of the ECR repository"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
