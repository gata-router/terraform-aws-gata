# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

data "archive_file" "lambda" {
  source_file = "${path.module}/handler/handler.py"
  output_path = "${path.module}/handler.zip"
  type        = "zip"
}

resource "aws_lambda_function" "this" {
  function_name = local.function_name

  filename         = data.archive_file.lambda.output_path
  handler          = "handler.handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256

  architectures = ["arm64"]
  memory_size   = 128
  runtime       = var.python_version
  timeout       = 5

  role = aws_iam_role.lambda.arn

  layers = [
    var.lambda_powertools_arn,
  ]

  tracing_config {
    mode = "Active"
  }

  tags = var.tags
}

resource "aws_iam_role" "lambda" {
  name = local.role_name

  assume_role_policy   = data.aws_iam_policy_document.lambda_assume.json
  permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
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

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    #tfsec:ignore:aws-iam-no-policy-wildcards Need wildcards to reference all possible log streams
    resources = [
      "${aws_cloudwatch_log_group.lambda.arn}:log-stream:*",
    ]
  }

  statement {
    actions = [
      "cloudwatch:PutMetricData",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda" {
  name   = aws_iam_role.lambda.name
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda" {
  policy_arn = aws_iam_policy.lambda.arn
  role       = aws_iam_role.lambda.name
}

data "aws_iam_policy" "xray_write_only" {
  name = "AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_xrays_write_only" {
  policy_arn = data.aws_iam_policy.xray_write_only.arn
  role       = aws_iam_role.lambda.name
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key CWL SSE is adequate for the data being logged
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 30

  tags = var.tags
}
