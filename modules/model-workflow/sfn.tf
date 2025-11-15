# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {

  sfn_definition = templatefile("${path.module}/workflow.asl.json", {

    data_bucket = var.bucket_data_name

    finetune_image_url          = var.finetune_image_url
    finetune_instance_type      = var.finetune_instance_type
    finetune_max_exec_time      = var.finetune_max_exec
    finetune_sagemaker_role_arn = aws_iam_role.sagemaker_finetune.arn

    inference_image_url          = var.inference_image_url
    inference_sagemaker_role_arn = aws_iam_role.sagemaker_inference.arn

    kms_key_arn = var.kms_key_arn

    model_bucket    = var.bucket_model_name
    model_namespace = var.model_namespace

    ssm_base_path = var.ssm_image_path

    tags = replace(jsonencode([for k, v in var.tags : { Key = k, Value = v }]), "\"", "'")

    train_on_spot = var.train_on_spot
  })

  sfn_name = "${var.model_namespace}-pipeline"

  sfn_role_name = join("", [(var.role_namespace != "" ? "${var.role_namespace}-" : ""), "sfn-", local.sfn_name])
}

resource "aws_sfn_state_machine" "model_pipeline" {
  name     = local.sfn_name
  role_arn = aws_iam_role.sfn_model_pipeline.arn

  encryption_configuration {
    type       = "CUSTOMER_MANAGED_KMS_KEY"
    kms_key_id = var.kms_key_arn

    kms_data_key_reuse_period_seconds = 300
  }

  definition = local.sfn_definition

  logging_configuration {
    level = "ERROR"

    include_execution_data = true
    log_destination        = "${aws_cloudwatch_log_group.sfn_model_pipeline.arn}:*"
  }

  tags = var.tags
}

# trivy:ignore:AVD-AWS-0017 CWL SSE is adequate for the data being logged
resource "aws_cloudwatch_log_group" "sfn_model_pipeline" {
  name = "/aws/vendedlogs/states/${local.sfn_name}"

  retention_in_days = var.log_retention_days

  tags = var.tags
}

data "aws_iam_policy_document" "sfn_model_pipeline_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        provider::aws::arn_build(data.aws_partition.current.id, "states", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "stateMachine:*"),
      ]
    }
  }
}

resource "aws_iam_role" "sfn_model_pipeline" {
  name = local.sfn_role_name

  assume_role_policy   = data.aws_iam_policy_document.sfn_model_pipeline_assume.json
  permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}

# trivy:ignore:avd-aws-0342 The SFn needs to pass the roles to SageMaker resources or they won't work.
data "aws_iam_policy_document" "sfn_model_pipeline" {

  statement {
    actions = [
      "events:DescribeRule",
      "events:PutRule",
      "events:PutTargets",
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.id, "events", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "rule/StepFunctions*"),
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]

    resources = [
      var.kms_key_arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]

    resources = [
      var.kms_key_arn,
    ]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  /* Turns out we can't scope to the log group. SageMaker insists on the broader permissions defined below 😡 */
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
      "sagemaker:AddTags",
      "sagemaker:CreateTrainingJob",
      "sagemaker:DescribeTrainingJob",
      "sagemaker:StopTrainingJob",
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.id, "sagemaker", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "training-job/${var.model_namespace}-*"),
    ]
  }

  statement {
    actions = [
      "sagemaker:CreateEndpoint",
      "sagemaker:DescribeEndpoint",
      "sagemaker:UpdateEndpoint",
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.id, "sagemaker", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "endpoint/${var.model_namespace}"),
    ]
  }

  statement {
    actions = [
      "sagemaker:CreateEndpoint", # I have no idea why SageMaker needs this permission on the config to create the endpoint, but it does - https://docs.aws.amazon.com/sagemaker/latest/dg/api-permissions-reference.html
      "sagemaker:CreateEndpointConfig",
      "sagemaker:DeleteEndpointConfig",
      "sagemaker:DescribeEndpointConfig",
      "sagemaker:UpdateEndpoint", # This, like the create, is needed for updating the endpoint 🤯
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.id, "sagemaker", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "endpoint-config/${var.model_namespace}-*"),
    ]
  }

  statement {
    actions = [
      "sagemaker:CreateModel",
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.id, "sagemaker", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "model/${var.model_namespace}-*"),
    ]
  }

  statement {
    actions = [
      "sagemaker:ListTags"
    ]

    # trivy:ignore:AVD-AWS-0143 Read only operation and need to reference all tags
    resources = ["*"]
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
  /*
  statement {
    actions = [
      "iam:PassRole"
    ]

    resources = [
      aws_iam_role.sagemaker_inference.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "sagemaker.amazonaws.com"
      ]
    }

    condition {
      test     = "ArnLike"
      variable = "iam:AssociatedResourceARN"
      values = [
        provider::aws::arn_build(data.aws_partition.current.id, "sagemaker", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "endpoint/${var.model_namespace}-*"),
      ]
    }
  }
*/
  statement {
    actions = [
      "iam:PassRole"
    ]

    resources = [
      aws_iam_role.sagemaker_inference.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "sagemaker.amazonaws.com"
      ]
    }
    /*
    condition {
      test     = "ArnLike"
      variable = "iam:AssociatedResourceARN"
      values = [
        provider::aws::arn_build(data.aws_partition.current.id, "sagemaker", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "model/${var.model_namespace}-*"),
      ]
    }
  */
  }

  statement {
    actions = [
      "iam:PassRole"
    ]

    resources = [
      aws_iam_role.sagemaker_finetune.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "sagemaker.amazonaws.com"
      ]
    }

    condition {
      test     = "ArnLike"
      variable = "iam:AssociatedResourceARN"
      values = [
        provider::aws::arn_build(data.aws_partition.current.id, "sagemaker", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "training-job/${var.model_namespace}-*"),
      ]
    }
  }
}

resource "aws_iam_policy" "sfn_model_pipeline" {
  name   = aws_iam_role.sfn_model_pipeline.name
  policy = data.aws_iam_policy_document.sfn_model_pipeline.json
}

resource "aws_iam_role_policy_attachment" "sfn_model_pipeline" {
  role       = aws_iam_role.sfn_model_pipeline.name
  policy_arn = aws_iam_policy.sfn_model_pipeline.arn
}
