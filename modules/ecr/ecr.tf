# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = data.aws_kms_key.gata.arn
  }

  tags = var.tags
}

resource "aws_ecr_repository_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.ecr.json
}

data "aws_iam_policy_document" "ecr" {
  statement {
    actions = [
      "ecr:*",
    ]

    principals {
      type = "AWS"
      identifiers = [
        var.admin_role_arn,
      ]
    }
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    principals {
      type = "AWS"
      identifiers = [
        data.aws_caller_identity.current.arn,
      ]
    }
  }
}
