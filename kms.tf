# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

resource "aws_kms_key" "this" {
  description = "${var.application_name} app - ${var.tags["environment"]} environment"

  deletion_window_in_days = 14
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.application_name}-${var.tags["environment"]}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.key_id
  policy = data.aws_iam_policy_document.kms.json
}

data "aws_iam_policy_document" "kms" {
  statement {
    actions = [
      "kms:*"
    ]

    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        local.admin_role_arn,
      ]
    }
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:List*",
      "kms:ReEncrypt*",
    ]

    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        data.aws_caller_identity.current.account_id,
      ]
    }
  }

  statement {
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]

    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}
