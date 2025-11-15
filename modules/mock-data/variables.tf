# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

variable "application_name" {
  description = "Name for the application. Used to prefix resources provisioned by this module."
  type        = string
}

variable "config_bucket_name" {
  description = "Name of the existing S3 bucket for storing config files."
  type        = string
}

variable "enable_hourly_tickets" {
  description = "Generate mock tickets every hour for testing purposes."
  type        = bool
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encryption at rest"
  type        = string
}

variable "lambda_ticket_create" {
  description = "Name of the PicoFun zendesk_post_api_v2_tickets Lambda function used to create the ticket"
  type        = string
  default     = "zendesk_post_api_v2_tickets"
}

variable "lambda_ticket_update" {
  description = "Name of the PicoFun zendesk_put_api_v2_tickets_ticket_id Lambda function used to update the ticket"
  type        = string
  default     = "zendesk_put_api_v2_tickets_ticket_id"
}

variable "role_namespace" {
  description = "Namespace/prefix for the Lambda execution role"
  type        = string
}

variable "role_permissions_boundary" {
  description = "Permissions boundary to apply to the Step Function execution role"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

locals {
  sfn_name = "${var.application_name}-${var.tags["environment"]}-mock-data-create-ticket"

  lambda_ticket_update_arn = provider::aws::arn_build(data.aws_partition.current.partition, "lambda", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "function:${var.lambda_ticket_update}")
}
