# Copyright 2024, Dave Hall, Skwashd Services Pty Ltd <me@davehall.com.au>, All Rights Reserved

data "aws_caller_identity" "current" {}

data "aws_kms_key" "gata" {
  key_id = var.kms_key_arn
}
