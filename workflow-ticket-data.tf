# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

module "workflow_ticket_data" {
  source = "./modules/workflow-ticket-data"

  kms_key_arn = aws_kms_key.this.arn

  lambda_prepare_text = module.prepare_text.lambda_function
  lambda_redact       = var.lambda_function_arns.redact
  lambda_ticket_get   = var.lambda_function_arns.ticket_get

  role_namespace            = var.role_namespace
  role_permissions_boundary = local.permissions_boundary

  tags = var.tags
}
