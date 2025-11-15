# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

variable "admin_role_arn" {
  description = "ARN of the admin role for managing sensitive resources."
  type        = string
}

variable "application_name" {
  description = "Name for the application. Used to prefix resources provisioned by this module."
  type        = string
  default     = "gata"
}

variable "data_api_vpce_security_group" {
  description = "ID of the security group for the VPC endpoint for the RDS data API"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for encryption"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch Logs"
  type        = number
}

variable "scaling" {
  description = "The scaling configuration for the database."
  type = object({
    min = number
    max = number
  })
}

variable "subnet_ids" {
  description = "List of subnet IDs to use for the database cluster"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
