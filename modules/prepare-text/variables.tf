# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

variable "application_name" {
  description = "Namespace/prefix for the Lambda function"
  type        = string
}

variable "lambda_powertools_arn" {
  type        = string
  description = "ARN of the AWS Lambda Powertools Lambda layer"
}

variable "role_namespace" {
  description = "Namespace/prefix for the Lambda execution role"
  type        = string
  default     = ""
}

variable "role_permissions_boundary" {
  description = "Permissions boundary to apply to the Lambda execution role"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

locals {
  function_name = "${var.application_name}-prepare-text"

  python_version = "python3.13"

  role_name = join("", [(var.role_namespace != "" ? "${var.role_namespace}-" : ""), local.function_name])
}
