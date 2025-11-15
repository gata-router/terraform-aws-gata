# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

module "s3" {
  for_each = toset(["data", "model", "config"])
  source   = "./modules/s3"

  name = "${var.application_name}-${data.aws_caller_identity.current.account_id}-${var.tags["environment"]}-${each.key}"

  admin_role_arn = local.admin_role_arn
  kms_key_arn    = aws_kms_key.this.arn
  logging_bucket = var.logging_bucket

  tags = var.tags
}
