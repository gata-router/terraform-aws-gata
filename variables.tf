# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

variable "admin_role" {
  description = "Details of the admin role for managing sensitive resources. The path is only needed if using a SSO role."
  type = object({
    name = string
    path = optional(string, "/")
  })
}

variable "application_name" {
  description = "Name for the application. Used to prefix resources provisioned by this module."
  type        = string
  default     = "gata"
}

variable "db_scaling" {
  description = "The scaling configuration for the database."
  type = object({
    min = optional(number, 0)
    max = optional(number, 2)
  })

  validation {
    condition     = var.db_scaling.min < var.db_scaling.max
    error_message = "The minimum database size must be less than the maximum."
  }

  validation {
    condition     = ((var.db_scaling.min * 2) % 1) == 0 || ((var.db_scaling.max * 2) % 1) == 0
    error_message = "Capacity units must be specified in half unit increments."
  }

  validation {
    condition     = (var.db_scaling.min >= 1 && var.tags.environment == "prod") || (var.db_scaling.min >= 0 && var.tags.environment != "prod")
    error_message = "The minimum database size must be greater than 0 for production environments."
  }

  validation {
    condition     = var.db_scaling.max <= 256
    error_message = "The maximum database size must not exceed 256."
  }
}

variable "enable_firehose" {
  description = "Enable the Firehose delivery stream for writing tickets events to S3."
  type        = bool
  default     = true
}

variable "enable_mock_data" {
  description = "Enable the mock data generator resources. Use this to generate and load sample ticket data. Do not use on production systems."
  type        = bool
  default     = false
}

variable "enable_test_tickets" {
  description = "Generate a test ticket once an hour. Provides sample data for testing and system validation. Do not use on production systems."
  type        = bool
  default     = false

  validation {
    condition     = !(var.enable_test_tickets && !var.enable_mock_data)
    error_message = "Test tickets can only be enabled if mock data generation is also enabled."
  }
}

variable "finetune_max_exec" {
  description = "Maximum execution time for the fine-tuning job"
  type        = number
  default     = 7200 # = 2 * 60 * 60 = 2 hours in seconds
}

variable "github_pipeline_config" {
  description = "Configuration for the GitHub Actions pipelines for ECR images. Leave empty to disable. If environment isn't set, the pipeline will allow any tags to push images."
  default     = null

  type = object({
    env         = optional(string)
    org         = string
    repo_prefix = optional(string, "")
  })
}

variable "github_oidc_provider_arn" {
  description = "ARN of the existing GitHub OIDC provider in AWS IAM. Leave empty to create a new provider."
  type        = string
  default     = ""
}

variable "lambda_function_arns" {
  description = "ARNs for Lambda functions invoked in the workflows"
  type = object({
    redact          = string               # From proactiveops/util-fns
    ticket_get      = string               # "arn:aws:lambda:us-east-1:012345678910:function:zendesk_get_api_v2_tickets_ticket_id",
    ticket_comments = string               # "arn:aws:lambda:us-east-1:012345678910:function:zendesk_get_api_v2_tickets_ticket_id_comments",
    ticket_create   = string               # "arn:aws:lambda:us-east-1:012345678910:function:zendesk_post_api_v2_tickets",
    ticket_update   = optional(string, "") # If left empty, noop function will be used # "arn:aws:lambda:us-east-1:012345678910:function:zendesk_put_api_v2_tickets_ticket_id",
    user_get        = string               # "arn:aws:lambda:us-east-1:012345678910:function:zendesk_get_api_v2_users_user_id",
  })
}

variable "lambda_powertools_version" {
  type        = number
  description = "The version of the AWS Lambda Powertools Lambda layer. Set to 0 if you want to always use the latest version."
  default     = 0
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch Logs"
  type        = number
  default     = 30
}

variable "logging_bucket" {
  description = "Bucket to store S3 logs. Must be in the same region and account. Leave empty to disable."
  type        = string
  default     = ""
}

variable "low_volume_fallback_label" {
  description = "Label to use when there is insufficient low volume ticket data to train a model."
  type        = number
}

variable "override_image_tags" {
  description = "Versions of the ECR images to use. Leave empty to use the latest image available. During initial setup, set the values to ':latest'."
  default     = {}

  type = object({
    data_prep = optional(string, null)
    finetune  = optional(string, null)
    inference = optional(string, null)
  })
}

variable "role_namespace" {
  description = "Namespace/prefix for IAM roles. Prepended to the application name."
  type        = string
  default     = ""
}

variable "role_permissions_boundary" {
  description = "Permissions boundary to apply to IAM roles"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs to use for the database cluster"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "The 'subnet_ids' variable must contain at least one subnet ID."
  }

  validation {
    condition     = alltrue([for s in var.subnet_ids : length(regexall("^subnet-([a-f0-9]+)$", s)) == 1])
    error_message = "The 'subnet_ids' variable must contain valid subnet IDs."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)

  validation {
    condition     = alltrue([for t in ["environment"] : contains(keys(var.tags), t)])
    error_message = "The 'tags' variable must include the following keys: 'environment'"
  }
}

variable "train_on_spot" {
  description = "Use spot instances for fine tuning the models."
  type        = bool
  default     = true
}

variable "vpc_endpoints" {
  description = "Security groups for VPC endpoints used for accessing AWS services. Format <service-name> = <security-group-id>. Replace . in the service name with -. If endpoint not provided, egress to 0.0.0.0/0 is allowed."

  type    = map(string)
  default = {}

  validation {
    condition     = alltrue([for v in values(var.vpc_endpoints) : length(regexall("^sg-([a-f0-9]{8,})$|^pl-([a-z0-9]+)$", v)) == 1])
    error_message = "Each VPC endpoint security group ID must be a valid security group ID."
  }

  validation {
    condition     = alltrue([for k in keys(var.vpc_endpoints) : length(regexall("^[a-z0-9-]+$", k)) > 0])
    error_message = "Each VPC endpoint service name must only contain lowercase letters, numbers, and hyphens."
  }
}

locals {

  admin_role_arn = one(data.aws_iam_roles.admin.arns)

  python_version = "python3.13"

  lambda_powertools_arn = (
    var.lambda_powertools_version == 0
    ? nonsensitive(data.aws_ssm_parameter.lambda_powertools_layer[0].value)
    : "arn:aws:lambda:${data.aws_region.current.name}:017000801446:layer:AWSLambdaPowertoolsPythonV3-${replace(local.python_version, ".", "")}-arm64:${var.lambda_powertools_version}"
  )

  permissions_boundary = var.role_permissions_boundary != null ? data.aws_iam_policy.permissions_boundary[0].arn : null
}
