# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

variable "bucket_data_arn" {
  description = "ARN of the S3 bucket containing the training data."
  type        = string
}

variable "bucket_data_name" {
  description = "Name of the S3 bucket containing the training data."
  type        = string
}

variable "bucket_model_arn" {
  description = "ARN of the S3 bucket used for storing the model artifacts."
  type        = string
}

variable "bucket_model_name" {
  description = "Name of the S3 bucket used for storing the model artifacts."
  type        = string
}

variable "finetune_image_arn" {
  description = "ARN of the ECR image to use for fine-tuning"
  type        = string
}

variable "finetune_image_url" {
  description = "The URL of the ECR image to use for fine-tuning"
  type        = string
}

variable "finetune_instance_type" {
  description = "Instance type to use for fine-tuning"
  type        = string
  default     = "ml.g6.xlarge"
}

variable "finetune_max_exec" {
  description = "Maximum execution time for the fine-tuning job"
  type        = number
}

variable "inference_image_arn" {
  description = "ARN of the ECR image to use for inference"
  type        = string
}

variable "inference_image_url" {
  description = "The URL of the ECR image to use for inference"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encryption at rest"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch Logs"
  type        = number
}

variable "model_namespace" {
  description = "Namespace used by this model"
  type        = string
  default     = "gata"
}

variable "role_namespace" {
  description = "Namespace/prefix for the IAM roles"
  type        = string
  default     = ""
}

variable "role_permissions_boundary" {
  description = "Permissions boundary to apply to IAM roles"
  type        = string
  default     = ""
}

variable "ssm_image_path" {
  description = "The base SSM path for image versions parameters."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "train_on_spot" {
  description = "Use spot instances for fine tuning the models."
  type        = bool
}
