# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_iam_roles" "admin" {
  name_regex  = "${var.admin_role.name}.*"
  path_prefix = var.admin_role.path
}

data "aws_iam_policy" "permissions_boundary" {
  count = var.role_permissions_boundary != null ? 1 : 0

  name = var.role_permissions_boundary
}

data "aws_ssm_parameter" "lambda_powertools_layer" {
  count = var.lambda_powertools_version == 0 ? 1 : 0

  name = "/aws/service/powertools/python/arm64/${local.python_version}/latest"
}
