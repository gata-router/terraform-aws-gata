# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {
  inference_role_name = join("", [var.role_namespace != "" ? "${var.role_namespace}-" : "", var.model_namespace, "-inference"])
}


resource "aws_iam_role" "sagemaker_inference" {
  name = local.inference_role_name

  assume_role_policy   = data.aws_iam_policy_document.sagemaker_assume.json
  permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}

resource "aws_iam_policy" "sagemaker_inference" {
  name        = aws_iam_role.sagemaker_inference.name
  description = "Policy for inference of the ${var.model_namespace} model"
  policy      = data.aws_iam_policy_document.sagemaker_inference.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "sagemaker_inference" {
  role       = aws_iam_role.sagemaker_inference.name
  policy_arn = aws_iam_policy.sagemaker_inference.arn
}


data "aws_iam_policy_document" "sagemaker_inference" {

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

    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]

    resources = [
      var.inference_image_arn,
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
      "logs:CreateLogGroup",
    ]

    # trivy:ignore:AVD-AWS-0143 Wildcard is necessary for CloudWatch Log streams
    resources = [
      provider::aws::arn_build(data.aws_partition.current.id, "logs", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "log-group:/aws/sagemaker/Endpoints/${var.model_namespace}-*"),
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    # trivy:ignore:AVD-AWS-0143 Wildcard is necessary for CloudWatch Log streams
    resources = [
      provider::aws::arn_build(data.aws_partition.current.id, "logs", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "log-group:/aws/sagemaker/Endpoints/${var.model_namespace}-*:log-stream:*"),
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      var.bucket_data_arn,
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    # trivy:ignore:AVD-AWS-0143Wildcard is necessary to reference the model
    resources = [
      "${var.bucket_model_arn}/model/${var.model_namespace}/*/output/model/model.tar.gz",
    ]
  }
}
