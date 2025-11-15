# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encryption at rest"
  type        = string
}

variable "lambda_prepare_text" {
  description = "ARN of the Lambda function used to prepare the text"
  type        = string
  default     = "gata-prepare-text"
}

variable "lambda_redact" {
  description = "ARN of the Lambda function used to redact text"
  type        = string
  default     = "util-fns-redact"
}

variable "lambda_ticket_get" {
  description = "ARN of the PicoFun zendesk_get_api_v2_tickets_ticket_id Lambda function used to fetch the ticket"
  type        = string
  default     = "zendesk_get_api_v2_tickets_ticket_id"
}

variable "role_namespace" {
  description = "Namespace/prefix for the Lambda execution role"
  type        = string
  default     = ""
}

variable "role_permissions_boundary" {
  description = "Permissions boundary to apply to the Step Function execution role"
  type        = string
  default     = null
}


variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

locals {
  sfn_role_name = join("", [(var.role_namespace != "" ? "${var.role_namespace}-" : ""), "gata-sfn-ticket-data"])

  sfn_name = "gata-ticket-data"
}
