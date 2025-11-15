# Ticket Data Firehose

Delivers ticket events from EventBridge to S3 for long-term storage, audit, and data lake use cases.

## Purpose

This module provisions Amazon Data Firehose to capture all Zendesk ticket events and store them in S3. While not required for GATA's core ticket routing functionality, it provides:

- **Audit trail** - Complete history of all ticket events for compliance and troubleshooting
- **Data lake** - Raw ticket data for analytics, reporting, and business intelligence
- **Reprocessing** - Ability to replay historical events if needed
- **Backup** - Redundant copy of ticket data outside the operational database

The module is a remnant of an earlier implementation but remains useful for organizations that want comprehensive ticket event retention.

## Data Flow

EventBridge captures all events from the `zendesk.com` source and delivers them to the Firehose delivery stream. The stream buffers events and writes them to S3 in compressed batches.

## Configuration

The module is enabled by default but can be disabled by setting `enable_firehose = false` in the root module configuration.

Events are written to the S3 data bucket with automatic partitioning by date.

# Generated Terraform Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0, < 2.0.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.0.0, < 3.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_stream.firehose_s3_delivery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_stream) | resource |
| [aws_iam_policy.eventbridge_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.eventbridge_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.eventbridge_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kinesis_firehose_delivery_stream.events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_firehose_delivery_stream) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.eventbridge_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eventbridge_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.firehose_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eventbus"></a> [eventbus](#input\_eventbus) | Name of the existing EventBridge custom bus | `string` | n/a | yes |
| <a name="input_kms_key"></a> [kms\_key](#input\_kms\_key) | ARN of the existing KMS key for encryption | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain logs in CloudWatch Logs | `number` | n/a | yes |
| <a name="input_role_namespace"></a> [role\_namespace](#input\_role\_namespace) | Namespace/prefix for the Lambda execution role | `string` | n/a | yes |
| <a name="input_role_permissions_boundary"></a> [role\_permissions\_boundary](#input\_role\_permissions\_boundary) | Permissions boundary to apply to the Step Function execution role | `string` | n/a | yes |
| <a name="input_s3_bucket_arn"></a> [s3\_bucket\_arn](#input\_s3\_bucket\_arn) | ARN of the bucket for data delivery | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eventbridge_rule_name"></a> [eventbridge\_rule\_name](#output\_eventbridge\_rule\_name) | Name of the EventBridge rule |
| <a name="output_firehose_role_arn"></a> [firehose\_role\_arn](#output\_firehose\_role\_arn) | ARN of the Firehose service role |
| <a name="output_stream_arn"></a> [stream\_arn](#output\_stream\_arn) | ARN of the Kinesis Data Firehose delivery stream |
| <a name="output_stream_name"></a> [stream\_name](#output\_stream\_name) | Name of the Kinesis Data Firehose delivery stream |
<!-- END_TF_DOCS -->