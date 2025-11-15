# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

variable "application_name" {
  description = "Name for the application. Used to prefix resources provisioned by this module."
  type        = string
}

variable "eventbus_name" {
  description = "Name of the EventBridge event bus"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for encryption"
  type        = string
}

variable "lambda_powertools_arn" {
  description = "ARN of the Lambda Powertools layer"
  type        = string
}

variable "python_version" {
  description = "Python version to use for the Lambda function"
  type        = string
}

variable "role_namespace" {
  description = "Namespace/prefix for the Lambda execution role"
  type        = string
}

variable "role_permissions_boundary" {
  description = "Permissions boundary to apply to the Lambda execution role"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "webhook_creds" {
  description = "Name of the SSM parameter containing the webhook credentials"
  type        = string
}

locals {
  function_name = "${var.application_name}-zendesk-webhook-handler"

  role_name = join("", [(var.role_namespace != "" ? "${var.role_namespace}-" : ""), local.function_name])
}
