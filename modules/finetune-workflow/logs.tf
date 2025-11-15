# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

#trivy:ignore:AVD-AWS-0017 CWL SSE is adequate for the data we're logging
resource "aws_cloudwatch_log_group" "ecs_data_prep" {
  name              = "/ecs/${local.data_prep_namespace}"
  retention_in_days = 30
}

# trivy:ignore:AVD-AWS-0017 CWL SSE is adequate for the data being logged
resource "aws_cloudwatch_log_group" "sfn" {
  name = "/aws/vendedlogs/states/${local.sfn_name}"

  retention_in_days = 30

  tags = var.tags
}
