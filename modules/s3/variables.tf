# Copyright 2024, Dave Hall, Skwashd Services Pty Ltd <me@davehall.com.au>, All Rights Reserved

variable "admin_role_arn" {
  description = "ARN of the IAM role to use for admin access"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encryption at rest"
  type        = string
}

variable "logging_bucket" {
  description = "The name of the S3 bucket to use for logging"
  type        = string
}

variable "name" {
  description = "The name of the S3 bucket repository"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
