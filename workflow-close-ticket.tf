# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

module "workflow_close_ticket" {
  source = "./modules/workflow-close-ticket"

  application_name = var.application_name

  db_cluster_arn = module.db.cluster_arn
  db_secret_arn  = module.db.secrets["user"]

  eventbus = module.eventbus_gata.bus.name

  kms_key_arn = aws_kms_key.this.arn

  lambda_ticket_comments = var.lambda_function_arns.ticket_comments
  lambda_ticket_update   = var.lambda_function_arns.ticket_update != "" ? var.lambda_function_arns.ticket_update : module.mock_router.lambda_function_arn
  lambda_user_get        = var.lambda_function_arns.user_get

  role_namespace            = var.role_namespace
  role_permissions_boundary = local.permissions_boundary

  sfn_ticket_data_name = module.workflow_ticket_data.sfn_name

  ssm_params = {
    group_mappings = aws_ssm_parameter.filters["group_mappings"].name
  }

  tags = var.tags
}
