
# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {
  github_domain = "token.actions.githubusercontent.com"


  github_subjects = (
    var.github_env != null
    ? ["repo:${var.github_org}/${var.github_repo}:environment:${var.github_env}"]
    : ["repo:${var.github_org}/${var.github_repo}:ref:refs/tags/*", "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"]
  )

  github_url = "https://${local.github_domain}"

  role_name = "${var.role_namespace}github-actions-${var.tags["environment"]}-${var.github_repo}"
}

data "aws_iam_policy_document" "github_oidc_assume" {

  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    principals {
      type = "Federated"
      identifiers = [
        var.github_oidc_provider_arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_domain}:aud"
      values = [
        "sts.amazonaws.com",
      ]
    }

    condition {
      test     = "StringLike" # "ForAnyValue:StringLike"
      variable = "${local.github_domain}:sub"
      values   = local.github_subjects
    }
  }
}

data "aws_iam_policy_document" "ecr_push" {

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage", # Needed for GHA
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    resources = [
      var.ecr_repo,
    ]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      var.kms_key_arn,
    ]
  }

  statement {
    actions = [
      "ssm:PutParameter",
    ]

    resources = [
      var.ssm_param_arn,
    ]
  }
}

resource "aws_iam_role" "github_actions" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume.json

  permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}

resource "aws_iam_policy" "github_actions" {
  name   = aws_iam_role.github_actions.name
  policy = data.aws_iam_policy_document.ecr_push.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
