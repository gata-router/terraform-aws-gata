# Copyright 2024, Dave Hall, Skwashd Services Pty Ltd <me@davehall.com.au>, All Rights Reserved

# trivy:ignore:AVD-AWS-0089 Logging is enabled if the user provides a logging bucket
resource "aws_s3_bucket" "this" {
  bucket = var.name

  force_destroy = false

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

data "aws_iam_policy_document" "s3" {
  statement {
    effect = "Deny"

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      type = "*"
      identifiers = [
        "*"
      ]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }

  statement {
    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      type = "AWS"
      identifiers = [
        var.admin_role_arn,
      ]
    }
  }

  statement {
    actions = [
      "s3:GetBucket*",
      "s3:ListBucket*",
    ]

    resources = [
      aws_s3_bucket.this.arn,
    ]

    principals {
      type = "AWS"
      identifiers = [
        data.aws_caller_identity.current.account_id,
      ]
    }
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject*",
      "s3:GetObject*",
      "s3:List*",
      "s3:PutObject*",
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      type = "AWS"
      identifiers = [
        data.aws_caller_identity.current.account_id,
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.s3.json
}

resource "aws_s3_bucket_logging" "this" {
  for_each = var.logging_bucket != "" ? toset([var.logging_bucket]) : []

  bucket = aws_s3_bucket.this.id

  target_bucket = each.value
  target_prefix = "s3/${aws_s3_bucket.this.id}/"
}
