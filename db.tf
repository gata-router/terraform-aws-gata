# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

module "db" {
  source = "./modules/db"

  admin_role_arn   = local.admin_role_arn
  application_name = var.application_name

  data_api_vpce_security_group = lookup(var.vpc_endpoints, "rds-data", "")

  kms_key_arn = aws_kms_key.this.arn

  log_retention_days = var.log_retention_days

  scaling = var.db_scaling

  subnet_ids = var.subnet_ids

  tags = var.tags
}
