variable "ecr_repo" {
  description = "ARN of the ECR repository."
  type        = string
}

variable "github_env" {
  description = "The name of the GitHub environment used when running the deployment."
  type        = string
}

variable "github_oidc_provider_arn" {
  description = "ARN of the existing GitHub OIDC provider in AWS IAM. Leave empty to create a new provider."
  type        = string
  default     = ""
}

variable "github_org" {
  description = "The GitHub organization for the repository."
  type        = string
}

variable "github_repo" {
  description = "The name of the GitHub repository."
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encrypting the ECR images at rest."
  type        = string
}

variable "role_namespace" {
  description = "Namespace/prefix for the IAM roles. Prepended to the application name."
  type        = string
}

variable "role_permissions_boundary" {
  description = "Permissions boundary to apply to IAM roles"
  type        = string
}

variable "ssm_param_arn" {
  description = "The ARN of the SSM parameter to use for storing the image version."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}
