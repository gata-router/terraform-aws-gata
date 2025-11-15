# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/handler/handler.py"
  output_path = "${path.module}/handler.zip"
}

# Lambda Function
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

  environment {
    variables = {
      CREDENTIALS_PARAM_PATH = var.webhook_creds
      EVENT_BUS_NAME         = var.eventbus_name
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = var.tags
}

# trivy:ignore:AVD-AWS-0017 Not logging sensitive data so CWL SSE is adequate
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 30
  tags              = var.tags
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = local.role_name
  tags = var.tags

  permissions_boundary = var.role_permissions_boundary

  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
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
      "events:PutEvents",
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.partition, "events", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "event-bus/${var.eventbus_name}"),
    ]
  }

  statement {
    actions = [
      "kms:Decrypt",
    ]

    resources = [
      var.kms_key_arn
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.lambda.arn}:log-stream:*"
    ]
  }

  statement {
    actions = [
      "ssm:GetParameter",
    ]

    resources = [
      provider::aws::arn_build(data.aws_partition.current.partition, "ssm", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "parameter${var.webhook_creds}"),
    ]
  }
}

resource "aws_iam_policy" "lambda" {
  name   = local.role_name
  policy = data.aws_iam_policy_document.lambda.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

data "aws_iam_policy" "AWSXRayDaemonWriteAccess" {
  arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy_attachment" "AWSXRayDaemonWriteAccess" {
  role       = aws_iam_role.lambda.name
  policy_arn = data.aws_iam_policy.AWSXRayDaemonWriteAccess.arn
}

resource "aws_lambda_function_url" "this" {
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "furl_invoke" {
  statement_id_prefix = "InvokeFunctionUrl"

  action    = "lambda:InvokeFunctionUrl"
  principal = "*"

  function_name          = aws_lambda_function.this.function_name
  function_url_auth_type = aws_lambda_function_url.this.authorization_type
}

resource "aws_lambda_permission" "invoke" {
  statement_id_prefix = "InvokeFunction"

  action    = "lambda:InvokeFunction"
  principal = "*"

  invoked_via_function_url = true

  function_name = aws_lambda_function.this.function_name
}
