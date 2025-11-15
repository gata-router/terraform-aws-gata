# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

data "aws_iam_policy_document" "sfn_ticket_data_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "states.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "sfn_ticket_data" {
  name                 = local.sfn_role_name
  assume_role_policy   = data.aws_iam_policy_document.sfn_ticket_data_assume.json
  permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}

data "aws_iam_policy_document" "sfn_ticket_data" {

  statement {
    actions = [
      "bedrock:InvokeModel",
    ]

    resources = [
      data.aws_bedrock_foundation_model.titan_embed.model_arn,
    ]
  }

  statement {
    actions = [
      "comprehend:DetectPiiEntities"
    ]

    resources = ["*"]
  }

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
      "logs:CreateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:DescribeLogGroups",
      "logs:DescribeResourcePolicies",
      "logs:GetLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:UpdateLogDelivery",
    ]

    # trivy:ignore:AVD-AWS-0143 Need wildcards as per https://docs.aws.amazon.com/step-functions/latest/dg/cw-logs.html#cloudwatch-iam-policy
    resources = ["*"]
  }

  statement {
    actions = [
      "lambda:InvokeFunction"
    ]

    # trivy:ignore:AVD-AWS-0143 Referencing all versions of the lambda functions
    resources = [
      "${var.lambda_prepare_text}:*",
      "${var.lambda_redact}:*",
      "${var.lambda_ticket_get}:*",
    ]
  }

  statement {
    actions = [
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:PutTelemetryRecords",
      "xray:PutTraceSegments",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "sfn_ticket_data" {
  name   = aws_iam_role.sfn_ticket_data.name
  policy = data.aws_iam_policy_document.sfn_ticket_data.json
}

resource "aws_iam_role_policy_attachment" "sfn_ticket_data" {
  role       = aws_iam_role.sfn_ticket_data.name
  policy_arn = aws_iam_policy.sfn_ticket_data.arn
}
