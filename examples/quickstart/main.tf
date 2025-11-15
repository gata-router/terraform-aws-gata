# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {

  subnets = [ # Should all be private
    "subnet-aabbccddeeff00",
    "subnet-00112233445566",
    "subnet-66778899aabbcc",
  ]

  tags = {
    environment = "dev"
  }

  vpc_endpoints = {
    /*

    Uncomment and configure if using VPC endpoints

    "ecr-api" = "sg-01234567"
    "ecr-dkr" = "sg-89abcdef"

    lambda = "sg-12435678"

    logs = "sg-9abcdef0"

    "rds-data" = "sg-23456789"

    secretsmanager = "sg-abcdef01"

    ssm = "sg-34567890"

    # Gateways
    dynamodb = "pl-0a1b2c3d"
    s3       = "pl-4e5f6g7a"

    */
  }
}

module "gata" {
  source = "../../"

  admin_role = {
    name = "AWSReservedSSO_AdministratorAccess"
    path = "/aws-reserved/sso.amazonaws.com/"
  }

  db_scaling = {
    min = 0
    max = 1
  }

  github_pipeline_config = {
    org         = "<your-github-org>"
    repo_prefix = "gata-"
  }

  override_image_tags = {
    data_prep = ":latest"
    finetune  = ":latest"
    inference = ":latest"
  }

  lambda_function_arns = {
    redact          = module.util_fns.lambda_function_arns["redact"]
    ticket_comments = module.picofun_zendesk.lambda_function_arns["get_api_v2_tickets_ticket_id_comments"]
    ticket_create   = module.picofun_zendesk.lambda_function_arns["post_api_v2_tickets"]
    ticket_get      = module.picofun_zendesk.lambda_function_arns["get_api_v2_tickets_ticket_id"]
    user_get        = module.picofun_zendesk.lambda_function_arns["get_api_v2_users_user_id"]

    # Uncomment this to run in production mode.
    # ticket_update = module.picofun_zendesk.lambda_function_arns["put_api_v2_tickets_ticket_id"]
  }

  low_volume_fallback_label = 0

  subnet_ids = local.subnets

  vpc_endpoints = local.vpc_endpoints

  tags = local.tags
}

module "util_fns" {
  source = "github.com/proactiveops/util-fns?ref=9b52f97" # @ v0.9.0 release

  subnets = local.subnets

  tags = local.tags
}

module "picofun_zendesk" {
  source = "./modules/picofun-zendesk"

  tags = local.tags
}
