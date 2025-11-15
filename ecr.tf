# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {
  ecr_repos = toset(["data-prep", "finetune", "inference"])
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.github_oidc_provider_arn == "" ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

module "ecr" {
  for_each = local.ecr_repos
  source   = "./modules/ecr"

  name = "${var.application_name}-${each.key}"

  admin_role_arn = local.admin_role_arn
  kms_key_arn    = aws_kms_key.this.arn

  image_tag = var.override_image_tags[each.key == "data-prep" ? "data_prep" : each.key]

  image_tag_param_name = aws_ssm_parameter.images[each.key].name

  tags = var.tags
}

module "ecr_github_actions" {
  for_each = var.github_pipeline_config != null ? module.ecr : {}
  source   = "./modules/oidc-pipeline"

  ecr_repo = each.value.repo_arn

  github_env  = var.github_pipeline_config.env
  github_org  = var.github_pipeline_config.org
  github_repo = join("", [var.github_pipeline_config.repo_prefix, each.key])

  github_oidc_provider_arn = var.github_oidc_provider_arn != "" ? var.github_oidc_provider_arn : aws_iam_openid_connect_provider.github[0].arn

  kms_key_arn = aws_kms_key.this.arn

  role_namespace            = var.role_namespace
  role_permissions_boundary = local.permissions_boundary

  ssm_param_arn = aws_ssm_parameter.images[each.key].arn

  tags = var.tags
}
