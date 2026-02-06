# Copyright 2025 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

module "workflow_assigned_ticket" {
  source = "./modules/workflow-assigned-ticket"

  application_name = var.application_name

  db_cluster_arn = module.db.cluster_arn
  db_secret_arn  = module.db.secrets["user"]

  eventbus = module.eventbus_gata.bus.name

  kms_key_arn = aws_kms_key.this.arn

  lambda_ticket_get_arn    = var.lambda_function_arns["ticket_get"]
  lambda_ticket_update_arn = var.lambda_function_arns["ticket_update"]

  role_namespace = var.role_namespace

  role_permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}
