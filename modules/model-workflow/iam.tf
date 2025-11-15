# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

data "aws_iam_policy_document" "sagemaker_assume" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "sagemaker.amazonaws.com"
      ]
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
