# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {
  firehose_stream_name = "gata-to-s3-${var.tags["environment"]}"
}

resource "aws_kinesis_firehose_delivery_stream" "events" {
  name        = local.firehose_stream_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = var.s3_bucket_arn

    buffering_size     = 128
    buffering_interval = 900

    dynamic_partitioning_configuration {
      enabled        = true
      retry_duration = 3600
    }

    prefix              = "raw-events/event_type=!{partitionKeyFromQuery:event_type}/year=!{partitionKeyFromQuery:year}/month=!{partitionKeyFromQuery:month}/day=!{partitionKeyFromQuery:day}/hour=!{partitionKeyFromQuery:hour}/"
    error_output_prefix = "error-records/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"
    file_extension      = ".json"

    kms_key_arn = var.kms_key

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_s3_delivery.name
    }

    processing_configuration {
      enabled = true

      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{event_type:.\"detail-type\",year:.detail.time[0:4],month:.detail.time[5:7],day:.detail.time[8:10],hour:.detail.time[11:13]}"
        }
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
      }
    }
  }

  server_side_encryption {
    enabled  = true
    key_type = "CUSTOMER_MANAGED_CMK"
    key_arn  = var.kms_key
  }

  tags = var.tags
}
