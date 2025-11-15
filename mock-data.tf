# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

module "mock_data" {
  count = var.enable_mock_data ? 1 : 0

  source = "./modules/mock-data"

  application_name = var.application_name

  config_bucket_name = module.s3["config"].bucket_name

  enable_hourly_tickets = var.enable_test_tickets

  kms_key_arn = aws_kms_key.this.arn

  lambda_ticket_create = var.lambda_function_arns.ticket_create
  lambda_ticket_update = var.lambda_function_arns.ticket_update

  role_namespace            = var.role_namespace
  role_permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}
