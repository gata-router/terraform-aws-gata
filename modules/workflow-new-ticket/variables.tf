# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

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

variable "inference_endpoints" {
  description = "Names of the SageMaker inference endpoints"
  type = object({
    general    = string
    low_volume = string
  })
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encryption at rest"
  type        = string
}

variable "lambda_ticket_update" {
  description = "Name of the PicoFun zendesk_put_api_v2_tickets_ticket_id Lambda function used to update the ticket"
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

variable "sfn_ticket_data_name" {
  description = "Name of the Step Function for the ticket data workflow"
  type        = string
}

variable "ssm_params" {
  description = "SSM parameters used to configure workflow customisations"
  type = object({
    exclude_requesters = string
    exclude_subjects   = string
    group_mappings     = string
  })
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

locals {
  eb_role_name  = join("", [(var.role_namespace != "" ? "${var.role_namespace}-" : ""), "${var.application_name}-eb-new-ticket"])
  sfn_role_name = join("", [(var.role_namespace != "" ? "${var.role_namespace}-" : ""), "${var.application_name}-sfn-new-ticket"])

  sfn_name = "${var.application_name}-new-ticket"

  sfn_ticket_data_arn      = provider::aws::arn_build(data.aws_partition.current.partition, "states", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "stateMachine:${var.sfn_ticket_data_name}")
  sfn_ticket_data_exec_arn = provider::aws::arn_build(data.aws_partition.current.partition, "states", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "execution:${var.sfn_ticket_data_name}/*")

  ssm_params = {
    for k, v in var.ssm_params : k => {
      arn  = provider::aws::arn_build(data.aws_partition.current.partition, "ssm", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "parameter${v}")
      name = v
    }
  }
}
