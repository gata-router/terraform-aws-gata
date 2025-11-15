# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {
  sfn_name = "${var.application_name}-${var.tags["environment"]}-finetune"

  sfn_role_name = "sfn-${local.sfn_name}"
}

resource "aws_sfn_state_machine" "finetune" {
  name     = local.sfn_name
  role_arn = aws_iam_role.sfn.arn

  encryption_configuration {
    type       = "CUSTOMER_MANAGED_KMS_KEY"
    kms_key_id = var.kms_key_arn

    kms_data_key_reuse_period_seconds = 300
  }

  definition = templatefile("${path.module}/workflow.asl.json", {
    data_prep_family = local.data_prep_namespace

    db_secret_arn = var.db_secret_arn

    event_bus_name = var.event_bus_name

    data_prep_ecr_image   = var.ecr_repo_urls["data-prep"]
    data_prep_log_group   = aws_cloudwatch_log_group.ecs_data_prep.name
    data_prep_role_exec   = aws_iam_role.data_prep_exec.arn
    data_prep_role_task   = aws_iam_role.data_prep_task.arn
    data_prep_task_prefix = local.data_prep_task_prefix

    db_cluster_arn = var.db_cluster_arn

    ecs_cluster_arn = var.ecs_cluster_arn

    low_volume_fallback_label = var.low_volume_fallback_label

    region = data.aws_region.current.name

    security_group_id = aws_security_group.this.id

    sfn_general_arn    = var.sfn_arns["general"]
    sfn_low_volume_arn = var.sfn_arns["low_volume"]

    subnet_ids = replace(jsonencode(var.subnet_ids), "\"", "'")

    s3_bucket = var.s3_bucket_name

    ssm_base_path = var.ssm_image_path
  })

  logging_configuration {
    level = "ERROR"

    include_execution_data = true
    log_destination        = "${aws_cloudwatch_log_group.sfn.arn}:*"
  }

  tracing_configuration {
    enabled = true
  }

  tags = var.tags
}
