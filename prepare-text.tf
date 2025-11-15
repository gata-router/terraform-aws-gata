# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

module "prepare_text" {
  source = "./modules/prepare-text"

  application_name = var.application_name

  lambda_powertools_arn = local.lambda_powertools_arn

  role_namespace            = var.role_namespace
  role_permissions_boundary = local.permissions_boundary

  tags = var.tags
}
