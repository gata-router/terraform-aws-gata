# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

data "aws_iam_policy_document" "firehose_assume" {
  statement {
    principals {
      type = "Service"
      identifiers = [
        "firehose.amazonaws.com"
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        # Referencing the Firehose stream ARN creates a loop 
        provider::aws::arn_build(
          data.aws_partition.current.partition,
          "firehose",
          data.aws_region.current.name,
          data.aws_caller_identity.current.account_id,
          "deliverystream/${local.firehose_stream_name}",
        )
      ]
    }
  }
}

resource "aws_iam_role" "firehose" {
  name                 = "${var.role_namespace}gata-firehose-delivery"
  permissions_boundary = var.role_permissions_boundary

  assume_role_policy = data.aws_iam_policy_document.firehose_assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "firehose" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      var.s3_bucket_arn,
    ]
  }


  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]

    resources = [
      "${var.s3_bucket_arn}/*"
    ]
  }


  # Statement for KMS access
  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
      "kms:Encrypt"
    ]

    resources = [
      var.kms_key
    ]
  }

  statement {
    actions = [
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_stream.firehose_s3_delivery.arn,
    ]
  }

}

resource "aws_iam_policy" "firehose" {
  name        = aws_iam_role.firehose.name
  description = "Allow firehose to deliver events to S3"
  policy      = data.aws_iam_policy_document.firehose.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "firehose" {
  role       = aws_iam_role.firehose.name
  policy_arn = aws_iam_policy.firehose.arn
}

data "aws_iam_policy_document" "eventbridge_assume" {
  statement {
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        aws_cloudwatch_event_rule.firehose.arn
      ]
    }
  }
}

resource "aws_iam_role" "eventbridge_firehose" {
  name                 = "${var.role_namespace}gata-eventbridge-to-firehose-${var.tags["environment"]}"
  permissions_boundary = var.role_permissions_boundary

  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "eventbridge_firehose" {
  statement {
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch"
    ]

    resources = [
      aws_kinesis_firehose_delivery_stream.events.arn
    ]
  }
}

resource "aws_iam_policy" "eventbridge_firehose" {
  name        = aws_iam_role.eventbridge_firehose.name
  description = "Allow EventBridge to put records to Firehose"
  policy      = data.aws_iam_policy_document.eventbridge_firehose.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eventbridge_firehose" {
  role       = aws_iam_role.eventbridge_firehose.name
  policy_arn = aws_iam_policy.eventbridge_firehose.arn
}
