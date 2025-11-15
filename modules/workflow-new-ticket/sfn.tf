# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {
  endpoint_name_general    = substr(provider::aws::arn_parse(var.inference_endpoints["general"]).resource, 9, -1)
  endpoint_name_low_volume = substr(provider::aws::arn_parse(var.inference_endpoints["low_volume"]).resource, 9, -1)
}

resource "aws_sfn_state_machine" "this" {
  name     = local.sfn_name
  role_arn = aws_iam_role.sfn_new_ticket.arn

  encryption_configuration {
    type       = "CUSTOMER_MANAGED_KMS_KEY"
    kms_key_id = var.kms_key_arn

    kms_data_key_reuse_period_seconds = 300
  }

  definition = templatefile("${path.module}/workflow.asl.json", {
    bedrock_model = data.aws_bedrock_foundation_model.priority.model_arn

    db_cluster_arn = var.db_cluster_arn
    db_secret_arn  = var.db_secret_arn

    kms_key_arn = var.kms_key_arn

    lambda_ticket_update_arn = var.lambda_ticket_update

    prompt = "'${trim(jsonencode(file("${path.module}/prompt.txt")), "\"")}'"

    sagemaker_endpoint_combined   = local.endpoint_name_general
    sagemaker_endpoint_low_volume = local.endpoint_name_low_volume

    sfn_ticket_data_arn = local.sfn_ticket_data_arn

    ssm_param_exclude_requesters = local.ssm_params.exclude_requesters.name
    ssm_param_exclude_subjects   = local.ssm_params.exclude_subjects.name
    ssm_param_group_mappings     = local.ssm_params.group_mappings.name
  })

  logging_configuration {
    level = "ALL"

    include_execution_data = true
    log_destination        = "${aws_cloudwatch_log_group.sfn_new_ticket.arn}:*"
  }

  tracing_configuration {
    enabled = true
  }

  tags = var.tags
}

# trivy:ignore:AVD-AWS-0017 CWL SSE is adequate for the data being logged
resource "aws_cloudwatch_log_group" "sfn_new_ticket" {
  name = "/aws/vendedlogs/states/${local.sfn_name}"

  retention_in_days = 30

  tags = var.tags
}
