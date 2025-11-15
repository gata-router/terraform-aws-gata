# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

variable "eventbus" {
  description = "Name of the existing EventBridge custom bus"
  type        = string
}

variable "kms_key" {
  description = "ARN of the existing KMS key for encryption"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch Logs"
  type        = number
}

variable "role_namespace" {
  description = "Namespace/prefix for the Lambda execution role"
  type        = string
}

variable "role_permissions_boundary" {
  description = "Permissions boundary to apply to the Step Function execution role"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the bucket for data delivery"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
