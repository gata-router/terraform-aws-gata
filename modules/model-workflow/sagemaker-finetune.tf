# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {
  finetune_role_name = join("", [var.role_namespace != "" ? "${var.role_namespace}-" : "", var.model_namespace, "-finetune"])

  # All logs flow into a common log group https://docs.aws.amazon.com/sagemaker/latest/dg/logging-cloudwatch.html
  training_job_log_arn = provider::aws::arn_build(data.aws_partition.current.id, "logs", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "log-group:/aws/sagemaker/TrainingJobs")
}

resource "aws_iam_role" "sagemaker_finetune" {
  name = local.finetune_role_name

  assume_role_policy   = data.aws_iam_policy_document.sagemaker_assume.json
  permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}

resource "aws_iam_policy" "sagemaker_finetune" {
  name        = aws_iam_role.sagemaker_finetune.name
  description = "Policy for fine tuning the ${var.model_namespace} model"
  policy      = data.aws_iam_policy_document.sagemaker_finetune.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "sagemaker_finetune" {
  role       = aws_iam_role.sagemaker_finetune.name
  policy_arn = aws_iam_policy.sagemaker_finetune.arn
}

data "aws_iam_policy_document" "sagemaker_finetune" {
  statement {
    actions = [
      "cloudwatch:PutMetricData"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    # trivy:ignore:AVD-AWS-0143 Account level permission
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]

    resources = [
      var.finetune_image_arn,
    ]
  }

  statement {
    # trivy:ignore:AVD-AWS-0143 Using recommended actions for encrypting outputs https://docs.aws.amazon.com/sagemaker/latest/dg/sms-security-kms-permissions.html#sms-security-kms-permissions-output-data
    actions = [
      "kms:CreateGrant", # Added after seeing failures on CloudTrail
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]

    resources = [
      var.kms_key_arn,
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup", # no idea why SageMaker insists on needing this
    ]

    resources = [
      "${local.training_job_log_arn}*", # Fails without the wildcard 🤷
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]

    resources = [
      "${local.training_job_log_arn}:log-stream:*",
    ]
  }

  statement {
    actions = [
      "s3:DeleteObject",
      "s3:PutObject",
    ]

    # trivy:ignore:AVD-AWS-0143 Need wildcards to reference all objects in the path
    resources = [
      "${var.bucket_model_arn}/model/${var.model_namespace}/*",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    # trivy:ignore:AVD-AWS-0143 Need wildcards to reference all objects in the path
    resources = [
      "${var.bucket_data_arn}/training/${var.model_namespace}/*",
      "${var.bucket_model_arn}/model/${var.model_namespace}/*",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      var.bucket_data_arn,
      var.bucket_model_arn,
    ]
  }
}
