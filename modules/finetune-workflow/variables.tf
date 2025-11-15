# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

variable "application_name" {
  description = "Name for the application. Used to prefix resources provisioned by this module."
  type        = string
  default     = "gata"
}

variable "db_cluster_arn" {
  description = "ARN of the existing RDS Aurora cluster"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the existing RDS Aurora secret"
  type        = string
}

variable "ecr_repo_arns" {
  description = "ARNs of the ECR repositories for the docker images. Format: { module_name => repo_arn }"
  type        = map(string)
}

variable "ecr_repo_urls" {
  description = "URLs of the ECR repositories for the docker images. Format: { module_name => repo_url }"
  type        = map(string)
}

variable "ecs_cluster_arn" {
  description = "ARN of the existing ECS cluster"
  type        = string
}

variable "event_bus_name" {
  description = "ARN of the EventBridge event bus to use for notifications"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for encryption"
  type        = string
}

variable "low_volume_fallback_label" {
  description = "Label to use when there is insufficient low volume ticket data to train a model."
  type        = number
}

variable "role_namespace" {
  description = "Namespace/prefix for IAMs roles"
  type        = string
  default     = ""
}

variable "role_permissions_boundary" {
  description = "Permissions boundary to apply to IAM roles"
  type        = string
  default     = null
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket to use for data storage"
  type        = string
}

variable "sfn_arns" {
  description = "ARNs of the Step Functions state machines for finetuning individual models. Format: { model_name => sfn_arn }"
  type        = map(string)
}

variable "ssm_image_path" {
  description = "The base SSM path for image versions parameters."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ECR task"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_endpoint_security_groups" {
  description = "Map of VPC endpoint security groups - `vpce => security_group_id`"
  type        = map(string)
}
