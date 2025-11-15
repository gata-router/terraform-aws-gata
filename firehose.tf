# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

module "firehose" {
  count  = var.enable_firehose ? 1 : 0
  source = "./modules/firehose"

  eventbus           = module.eventbus_zendesk.bus.name
  kms_key            = aws_kms_key.this.arn
  log_retention_days = var.log_retention_days

  role_namespace            = var.role_namespace
  role_permissions_boundary = var.role_permissions_boundary

  s3_bucket_arn = module.s3["data"].bucket_arn

  tags = var.tags
}
