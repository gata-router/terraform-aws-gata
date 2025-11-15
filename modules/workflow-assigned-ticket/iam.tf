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
      "bedrock:InvokeModel",
    ]

    resources = [
      data.aws_bedrock_foundation_model.priority.model_arn,
    ]
  }

  # This is needed to allow synchronous invocations of the nested step function
  statement {
    actions = [
      "events:DescribeRule",
      "events:PutRule",
      "events:PutTargets",
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.partition, "events", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "rule/StepFunctionsGetEventsForStepFunctionsExecutionRule"),
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
      "lambda:InvokeFunction",
    ]

    # trivy:ignore:AVD-AWS-0143 Referencing all versions of the lambda functions
    resources = [
      provider::aws::arn_build(data.aws_partition.current.partition, "lambda", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "function:${var.lambda_ticket_update}:*"),
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
      "sagemaker:invokeEndpoint"
    ]

    resources = [
      var.inference_endpoints["general"],
      var.inference_endpoints["low_volume"],
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
      "ssm:GetParameter",
    ]

    resources = [
      local.ssm_params.exclude_requesters.arn,
      local.ssm_params.exclude_subjects.arn,
      local.ssm_params.group_mappings.arn,
    ]
  }

  statement {
    actions = [
      "states:DescribeExecution",
      "states:StopExecution",
    ]

    # trivy:ignore:AVD-AWS-0143 Need wildcards when referencing executions
    resources = [
      "${local.sfn_ticket_data_exec_arn}:*",
    ]
  }

  statement {
    actions = [
      "states:StartExecution",
    ]

    # trivy:ignore:AVD-AWS-0143 Need wildcards to reference all possible versions of the state machine
    resources = [
      local.sfn_ticket_data_arn,
      "${local.sfn_ticket_data_arn}:*"
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
