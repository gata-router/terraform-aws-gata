# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {
  sfn_role_name_create      = join("", [(var.role_namespace != "" ? "${var.role_namespace}-" : ""), "${var.application_name}-mock-data-sfn-create-ticket"])
  schedule_close_role_name  = join("", [(var.role_namespace != "" ? "${var.role_namespace}-" : ""), "${var.application_name}-mock-data-scheduler-close-ticket"])
  schedule_ticket_role_name = join("", [(var.role_namespace != "" ? "${var.role_namespace}-" : ""), "${var.application_name}-mock-data-scheduler-hourly-ticket"])

}

data "aws_iam_policy_document" "sfn_assume" {
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

resource "aws_iam_role" "sfn_create_ticket" {
  name                 = local.sfn_role_name_create
  assume_role_policy   = data.aws_iam_policy_document.sfn_assume.json
  permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}

# trivy:ignore:AVD-AWS-0342 The SFn needs to pass the roles to SageMaker resources or they won't work.
data "aws_iam_policy_document" "sfn_create_ticket" {

  statement {
    actions = [
      "bedrock:InvokeModel",
    ]

    resources = [
      data.aws_bedrock_foundation_model.nova_pro.model_arn,
    ]
  }

  statement {
    actions = [
      "iam:PassRole",
    ]

    resources = [
      aws_iam_role.close_scheduler.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "scheduler.amazonaws.com"
      ]
    }
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
      "lambda:InvokeFunction",
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.partition, "lambda", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "function:${var.lambda_ticket_create}"),
    ]
  }

  # Based on https://docs.aws.amazon.com/step-functions/latest/dg/cw-logs.html
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

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.partition, "s3", "", "", "${var.config_bucket_name}/create-tickets/*.json"),
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.partition, "s3", "", "", var.config_bucket_name),
    ]
  }

  statement {
    actions = [
      "scheduler:CreateSchedule",
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.partition, "scheduler", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "schedule/default/close-ticket-*"),
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

resource "aws_iam_policy" "sfn_create_ticket" {
  name   = aws_iam_role.sfn_create_ticket.name
  policy = data.aws_iam_policy_document.sfn_create_ticket.json
}

resource "aws_iam_role_policy_attachment" "sfn_create_ticket" {
  role       = aws_iam_role.sfn_create_ticket.name
  policy_arn = aws_iam_policy.sfn_create_ticket.arn
}

data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "scheduler.amazonaws.com"
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

resource "aws_iam_role" "hourly_ticket_scheduler" {
  count = var.enable_hourly_tickets ? 1 : 0

  name = local.schedule_ticket_role_name

  assume_role_policy   = data.aws_iam_policy_document.scheduler_assume.json
  permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}

data "aws_iam_policy_document" "hourly_ticket_scheduler" {
  count = var.enable_hourly_tickets ? 1 : 0

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
      "states:StartExecution",
    ]

    resources = [
      aws_sfn_state_machine.create.arn
    ]
  }

  statement {
    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.dlq_hourly[0].arn
    ]
  }
}

resource "aws_iam_policy" "hourly_ticket_scheduler" {
  count = var.enable_hourly_tickets ? 1 : 0

  name   = aws_iam_role.hourly_ticket_scheduler[0].name
  policy = data.aws_iam_policy_document.hourly_ticket_scheduler[0].json
}

resource "aws_iam_role_policy_attachment" "hourly_ticket_scheduler" {
  count = var.enable_hourly_tickets ? 1 : 0

  role       = aws_iam_role.hourly_ticket_scheduler[0].name
  policy_arn = aws_iam_policy.hourly_ticket_scheduler[0].arn
}

resource "aws_iam_role" "close_scheduler" {
  name                 = local.schedule_close_role_name
  assume_role_policy   = data.aws_iam_policy_document.scheduler_assume.json
  permissions_boundary = var.role_permissions_boundary
  tags                 = var.tags
}

data "aws_iam_policy_document" "close_scheduler" {

  statement {
    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.partition, "lambda", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "function:${var.lambda_ticket_update}"),
    ]
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
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.dlq_close.arn,
    ]
  }
}

resource "aws_iam_policy" "close_scheduler" {
  name   = aws_iam_role.close_scheduler.name
  policy = data.aws_iam_policy_document.close_scheduler.json
}

resource "aws_iam_role_policy_attachment" "close_scheduler" {
  role       = aws_iam_role.close_scheduler.name
  policy_arn = aws_iam_policy.close_scheduler.arn
}
