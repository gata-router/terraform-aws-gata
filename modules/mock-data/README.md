# Mock Ticket Data Generator

Generates synthetic Zendesk ticket data for testing and evaluation. Uses Amazon Nova Pro to create realistic ticket content.

## Purpose

This module creates infrastructure to generate mock support tickets for:

- Testing GATA workflows without production data
- Evaluating routing and prioritization accuracy
- Validating deployments before connecting to Zendesk
- Load testing the system

**Do not enable this module in production environments.** It is intended for testing and evaluation only.

## Generation Modes

The module supports three ways to generate mock tickets:

### Single Ticket Creation

The Step Functions state machine can be invoked manually to create individual test tickets on demand.

### Scheduled Generation

When `enable_hourly_tickets` is true, EventBridge Scheduler creates one test ticket every hour. This provides a steady stream of sample data for ongoing validation.

### Bulk Generation

The state machine supports generating multiple tickets in a single execution by providing a batch configuration. This is useful for initial data loading or load testing.

## Configuration

Enable the module by setting `enable_mock_data = true` in your root module configuration. 

Enable hourly test tickets with `enable_test_tickets = true` (requires `enable_mock_data` to be enabled).

Group configurations are loaded from `groups.json` which defines the ticket categories and content themes used for generation. Edit this to match your environment.

The structure of the `groups.json` file is as follows:

```json
{
  "groups": {
    "<GROUP-ID-1>": "<SUMMARY-OF-PURPOSE-OF-GROUP-1>",
    "<GROUP-ID-2>": "<SUMMARY-OF-PURPOSE-OF-GROUP-2>",
    "<GROUP-ID-3>": "<SUMMARY-OF-PURPOSE-OF-GROUP-3>",
    "<GROUP-ID-4>": "<SUMMARY-OF-PURPOSE-OF-GROUP-4>",
    "<GROUP-ID-5>": "<SUMMARY-OF-PURPOSE-OF-GROUP-5>",
    ...
  },
  "weighted_ids": [
    "<GROUP-ID-3>",
    "<GROUP-ID-1>",
    "<GROUP-ID-1>",
    "<GROUP-ID-4>",
    "<GROUP-ID-4>",
    "<GROUP-ID-2>",
    "<GROUP-ID-3>",
    "<GROUP-ID-3>",
    "<GROUP-ID-2>",
    "<GROUP-ID-3>",
    "<GROUP-ID-1>",
    "<GROUP-ID-1>",
    "<GROUP-ID-5>",
    "<GROUP-ID-2>",
    "<GROUP-ID-2>",
    "<GROUP-ID-1>",
    "<GROUP-ID-4>",
    "<GROUP-ID-1>"
  ]
}
```

Use `weighted_ids` to manage the probability of a group being selected. Each group must appear at least once. It is best to randomise the order of the list. `shuf` is your friend.

## Known Behavior

Approximately 1 in 1000 generated tickets may contain invalid JSON due to the stochastic nature of the LLM generation. These are captured in the DLQ. Adding validation and retry logic was deemed unnecessary for a testing-only module.

# Generated Terraform Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0, < 2.0.0 |
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
| [aws_cloudwatch_log_group.sfn_create](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.close_scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.hourly_ticket_scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.sfn_create_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.close_scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.hourly_ticket_scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.sfn_create_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.close_scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.hourly_ticket_scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.sfn_create_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_scheduler_schedule.hourly_ticket_scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule) | resource |
| [aws_sfn_state_machine.create](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sfn_state_machine) | resource |
| [aws_sqs_queue.dlq_close](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.dlq_hourly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_bedrock_foundation_model.nova_pro](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/bedrock_foundation_model) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.close_scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.hourly_ticket_scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.scheduler_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sfn_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sfn_create_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name for the application. Used to prefix resources provisioned by this module. | `string` | n/a | yes |
| <a name="input_config_bucket_name"></a> [config\_bucket\_name](#input\_config\_bucket\_name) | Name of the existing S3 bucket for storing config files. | `string` | n/a | yes |
| <a name="input_enable_hourly_tickets"></a> [enable\_hourly\_tickets](#input\_enable\_hourly\_tickets) | Generate mock tickets every hour for testing purposes. | `bool` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The ARN of the KMS key to use for encryption at rest | `string` | n/a | yes |
| <a name="input_lambda_ticket_create"></a> [lambda\_ticket\_create](#input\_lambda\_ticket\_create) | Name of the PicoFun zendesk\_post\_api\_v2\_tickets Lambda function used to create the ticket | `string` | `"zendesk_post_api_v2_tickets"` | no |
| <a name="input_lambda_ticket_update"></a> [lambda\_ticket\_update](#input\_lambda\_ticket\_update) | Name of the PicoFun zendesk\_put\_api\_v2\_tickets\_ticket\_id Lambda function used to update the ticket | `string` | `"zendesk_put_api_v2_tickets_ticket_id"` | no |
| <a name="input_role_namespace"></a> [role\_namespace](#input\_role\_namespace) | Namespace/prefix for the Lambda execution role | `string` | n/a | yes |
| <a name="input_role_permissions_boundary"></a> [role\_permissions\_boundary](#input\_role\_permissions\_boundary) | Permissions boundary to apply to the Step Function execution role | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->