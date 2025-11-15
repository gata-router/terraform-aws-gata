# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License


locals {
  data_prep_namespace = "${var.application_name}-${var.tags["environment"]}-data-prep"

  data_prep_role_name = join("", [(var.role_namespace != "" ? "${var.role_namespace}-" : ""), local.data_prep_namespace])

  data_prep_task_prefix         = "${local.data_prep_namespace}-"
  data_prep_task_definition_arn = provider::aws::arn_build(data.aws_partition.current.partition, "ecs", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "task-definition/${local.data_prep_namespace}")
}

data "aws_iam_policy_document" "data_prep_exec" {
  statement {
    resources = ["*"]

    actions = [
      "ecr:GetAuthorizationToken",
    ]
  }

  statement {

    resources = concat(
      [
        for repo in var.ecr_repo_arns : repo
      ],
      [
        for repo in var.ecr_repo_arns : "${repo}:*"
      ],
    )

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
  }

  statement {
    resources = [
      "${aws_cloudwatch_log_group.ecs_data_prep.arn}:log-stream:*",
    ]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

data "aws_iam_policy_document" "ecs_exec_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
}

resource "aws_iam_role" "data_prep_exec" {
  name                 = "${local.data_prep_role_name}-exec"
  assume_role_policy   = data.aws_iam_policy_document.ecs_exec_assume.json
  permissions_boundary = var.role_permissions_boundary
  tags                 = var.tags
}

resource "aws_iam_policy" "data_prep_exec" {
  name   = aws_iam_role.data_prep_exec.name
  policy = data.aws_iam_policy_document.data_prep_exec.json
}

resource "aws_iam_role_policy_attachment" "data_prep_exec" {
  policy_arn = aws_iam_policy.data_prep_exec.arn
  role       = aws_iam_role.data_prep_exec.name
}

data "aws_iam_policy_document" "data_prep_task" {

  statement {
    resources = ["*"]

    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface",
      "ec2:DeleteNetworkInterfacePermission",
      "ec2:Describe*",
      "ec2:DetachNetworkInterface",
    ]
  }

  statement {
    resources = [
      provider::aws::arn_build("aws", "events", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "rule/ecs-managed-*"),
    ]

    actions = [
      "events:DescribeRule",
      "events:ListTargetsByRule",
    ]
  }

  statement {
    resources = ["*"]

    actions = [
      "events:PutRule",
      "events:PutTargets",
    ]

    condition {
      test     = "StringEquals"
      variable = "events:ManagedBy"
      values   = ["ecs.amazonaws.com"]
    }
  }

  statement {
    resources = [
      provider::aws::arn_build("aws", "cloudwatch", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "alarm:*")
    ]

    actions = [
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm",
    ]
  }

  statement {
    resources = [
      var.kms_key_arn
    ]

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
  }

  statement {
    resources = [
      "${aws_cloudwatch_log_group.ecs_data_prep.arn}:log-stream:*",
    ]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    resources = [
      var.db_cluster_arn,
    ]

    actions = [
      "rds-data:ExecuteStatement",
    ]
  }

  statement {
    resources = [
      local.s3_bucket_arn,
    ]

    actions = [
      "s3:ListBucket",
    ]
  }

  statement {
    resources = [
      local.s3_bucket_arn,
      "${local.s3_bucket_arn}/*",
    ]

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
  }

  statement {
    resources = [
      var.db_secret_arn,
    ]

    actions = [
      "secretsmanager:GetSecretValue",
    ]
  }
}

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
}

resource "aws_iam_role" "data_prep_task" {
  name                 = "${local.data_prep_role_name}-task"
  assume_role_policy   = data.aws_iam_policy_document.ecs_task_assume.json
  permissions_boundary = var.role_permissions_boundary
  tags                 = var.tags
}

resource "aws_iam_policy" "data_prep_task" {
  name   = aws_iam_role.data_prep_task.name
  policy = data.aws_iam_policy_document.data_prep_task.json
}

resource "aws_iam_role_policy_attachment" "data_prep_task" {
  policy_arn = aws_iam_policy.data_prep_task.arn
  role       = aws_iam_role.data_prep_task.name
}
