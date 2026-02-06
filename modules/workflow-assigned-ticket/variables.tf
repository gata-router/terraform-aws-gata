# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

variable "application_name" {
  description = "Name for the application. Used to prefix resources provisioned by this module."
  type        = string
}

variable "db_cluster_arn" {
  description = "ARN of the existing RDS Aurora cluster"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the existing RDS Aurora secret"
  type        = string
}

variable "eventbus" {
  description = "Name of the existing EventBridge event bus"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encryption at rest"
  type        = string
}

variable "lambda_ticket_get_arn" {
  description = "ARN of the PicoFun zendesk_get_api_v2_tickets_ticket_id Lambda function used to get the ticket details"
  type        = string
}

variable "lambda_ticket_update_arn" {
  description = "ARN of the PicoFun zendesk_put_api_v2_tickets_ticket_id Lambda function used to update the ticket"
  type        = string
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
  eb_role_name  = join("", [(var.role_namespace != "" ? "${var.role_namespace}-" : ""), "${var.application_name}-eb-assigned-ticket"])
  sfn_role_name = join("", [(var.role_namespace != "" ? "${var.role_namespace}-" : ""), "${var.application_name}-sfn-assigned-ticket"])

  sfn_name = "${var.application_name}-assigned-ticket"
}
