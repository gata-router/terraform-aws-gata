# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

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

resource "aws_iam_role" "sfn" {
  name                 = local.sfn_role_name
  assume_role_policy   = data.aws_iam_policy_document.sfn_assume.json
  permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}

#trivy:ignore:AVD-AWS-0342 Limited to specific roles
data "aws_iam_policy_document" "sfn" {

  statement {
    actions = [
      "ecs:DeregisterTaskDefinition",
    ]

    # Doesn't allow resource-level permissions
    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "ecs:RegisterTaskDefinition",
    ]

    resources = [
      "${local.data_prep_task_definition_arn}:*",
    ]
  }

  statement {
    actions = [
      "ecs:RunTask",
      "ecs:StopTask",
    ]

    resources = [
      "${local.data_prep_task_definition_arn}:*",
      var.ecs_cluster_arn
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
      provider::aws::arn_build(data.aws_partition.current.partition, "events", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "rule/StepFunctionsGetEventsForECSTaskRule"),
      provider::aws::arn_build(data.aws_partition.current.partition, "events", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "rule/StepFunctionsGetEventsForStepFunctionsExecutionRule"),
    ]
  }

  statement {
    actions = [
      "events:PutEvents",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:event-bus/${var.event_bus_name}",
    ]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]

    resources = [
      aws_iam_role.data_prep_exec.arn,
      aws_iam_role.data_prep_task.arn,
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
      "s3:GetObject",
    ]

    resources = [
      "${local.s3_bucket_arn}/training/gata-low-vol/*/train/data.json",
    ]
  }

  statement {
    # Needed when the object doesn't exist
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      local.s3_bucket_arn,
    ]
  }

  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.partition, "ssm", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "parameter${var.ssm_image_path}*"),
    ]
  }

  statement {
    actions = [
      "states:DescribeExecution",
      "states:StopExecution",
    ]

    # trivy:ignore:AVD-AWS-0143 Need wildcards when referencing executions
    resources = [
      for sfn_arn in values(var.sfn_arns) : "${sfn_arn}:*"
    ]
  }

  statement {
    actions = [
      "states:StartExecution",
    ]

    # trivy:ignore:AVD-AWS-0143 Need wildcards to reference all possible versions of the state machine
    resources = concat(
      [
        for sfn_arn in values(var.sfn_arns) : sfn_arn
      ],
      [
        for sfn_arn in values(var.sfn_arns) : "${sfn_arn}:*"
      ],
    )
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

resource "aws_iam_policy" "sfn" {
  name   = aws_iam_role.sfn.name
  policy = data.aws_iam_policy_document.sfn.json
}

resource "aws_iam_role_policy_attachment" "sfn" {
  role       = aws_iam_role.sfn.name
  policy_arn = aws_iam_policy.sfn.arn
}
