# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

data "aws_iam_policy_document" "sfn_new_ticket_assume" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "states.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }
  }
}

resource "aws_iam_role" "sfn_new_ticket" {
  name                 = local.sfn_role_name
  assume_role_policy   = data.aws_iam_policy_document.sfn_new_ticket_assume.json
  permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}

data "aws_iam_policy_document" "sfn_new_ticket" {

  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
    ]

    resources = [
      var.kms_key_arn,
    ]
  }

  statement {
    actions = [
      "lambda:InvokeFunction",
    ]

    # trivy:ignore:AVD-AWS-0143 Referencing all versions of the lambda functions
    resources = [
      "${var.lambda_ticket_get_arn}:*",
      "${var.lambda_ticket_update_arn}:*",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogDelivery",
      "logs:CreateLogStream",
      "logs:DeleteLogDelivery",
      "logs:DescribeLogGroups",
      "logs:DescribeResourcePolicies",
      "logs:GetLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutLogEvents",
      "logs:PutResourcePolicy",
      "logs:UpdateLogDelivery",
    ]

    # trivy:ignore:AVD-AWS-0143 Need wildcards as per https://docs.aws.amazon.com/step-functions/latest/dg/cw-logs.html#cloudwatch-iam-policy
    resources = ["*"]
  }

  statement {
    actions = [
      "rds-data:ExecuteStatement",
    ]

    resources = [
      var.db_cluster_arn,
    ]
  }

  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      var.db_secret_arn,
    ]
  }

  statement {
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
    ]

    # trivy:ignore:AVD-AWS-0143 Need wildcards to reference all possible resources
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sfn_new_ticket" {
  name   = aws_iam_role.sfn_new_ticket.name
  policy = data.aws_iam_policy_document.sfn_new_ticket.json
}

resource "aws_iam_role_policy_attachment" "sfn_new_ticket" {
  role       = aws_iam_role.sfn_new_ticket.name
  policy_arn = aws_iam_policy.sfn_new_ticket.arn
}
