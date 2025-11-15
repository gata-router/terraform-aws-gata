# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {
  ssm_base_path  = "/${var.application_name}/${var.tags["environment"]}/"
  ssm_image_path = "${local.ssm_base_path}image/"
}

resource "aws_ssm_parameter" "filters" {
  for_each = {
    exclude_requesters = [],
    exclude_subjects   = [],
    group_mappings     = {}
  }

  name = "${local.ssm_base_path}${each.key}"
  type = "String"

  value = jsonencode(each.value) # We only set this as an initial default so things don't break. The user is expected to set this.

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "images" {
  for_each = toset(["data-prep", "finetune", "inference"])

  name = "${local.ssm_image_path}version-${each.key}"
  type = "String"

  value = ":latest" # We only set this as an initial default. The pipeline will update it.

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "webhook_creds" {
  name   = "/${var.application_name}/${var.tags["environment"]}/webhook-creds"
  type   = "SecureString"
  key_id = aws_kms_key.this.arn

  value_wo = jsonencode({
    username = "SETME"
    password = "SETME"
  })
  value_wo_version = "0"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
