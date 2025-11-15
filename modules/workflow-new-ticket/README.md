# New Ticket Workflow

This module manages the workflow for routing a new ticket. There is a lot going on here.

First off we prepare the ticket data. This ensures data is in a consistent state.

Next we load some configuration from SSM Parameter Store. This allow some configuration updates without a redeployment.

If the group is already set we skip most of the processing. We assume that the group id is set correctly.

Some teams use Zendesk to capture status updates from other systems. I disagree with their poor decisions, but we have to live with it. We can exclude subjects associated with these use cases.

Next we prioritise the ticket based on the contents of the message.

There is a special place in hell for the teams what send system status updates to Zendesk with dynamic subject. For those we need to filter them out using the sender's email address.

Finally we're ready to ask the model where to send the ticket. If the group id returned is 0, that means the ticket should go to one of the low volume groups. In this case we ask a second model which low volume group the ticket should be sent to.

We update the ticket in Zendesk to set the group id. We also set some labels so the support agent is aware that gata routed the ticket.

Finally we store the ticket data in the database. We can use the data for vector search and reportings. Only when the ticket is closed do we use the data for training the model.

![New ticket workflow defined in Amazon Step Functions](workflow.png)

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
| [aws_cloudwatch_event_rule.new_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.new_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.sfn_new_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.eb_new_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.sfn_new_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.eb_new_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.sfn_new_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.eb_new_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.sfn_new_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_sfn_state_machine.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sfn_state_machine) | resource |
| [aws_bedrock_foundation_model.priority](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/bedrock_foundation_model) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.eb_new_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eb_new_ticket_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sfn_new_ticket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sfn_new_ticket_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name for the application. Used to prefix resources provisioned by this module. | `string` | n/a | yes |
| <a name="input_db_cluster_arn"></a> [db\_cluster\_arn](#input\_db\_cluster\_arn) | ARN of the existing RDS Aurora cluster | `string` | n/a | yes |
| <a name="input_db_secret_arn"></a> [db\_secret\_arn](#input\_db\_secret\_arn) | ARN of the existing RDS Aurora secret | `string` | n/a | yes |
| <a name="input_eventbus"></a> [eventbus](#input\_eventbus) | Name of the existing EventBridge event bus | `string` | n/a | yes |
| <a name="input_inference_endpoints"></a> [inference\_endpoints](#input\_inference\_endpoints) | Names of the SageMaker inference endpoints | <pre>object({<br/>    general    = string<br/>    low_volume = string<br/>  })</pre> | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The ARN of the KMS key to use for encryption at rest | `string` | n/a | yes |
| <a name="input_lambda_ticket_update"></a> [lambda\_ticket\_update](#input\_lambda\_ticket\_update) | Name of the PicoFun zendesk\_put\_api\_v2\_tickets\_ticket\_id Lambda function used to update the ticket | `string` | n/a | yes |
| <a name="input_role_namespace"></a> [role\_namespace](#input\_role\_namespace) | Namespace/prefix for the Lambda execution role | `string` | n/a | yes |
| <a name="input_role_permissions_boundary"></a> [role\_permissions\_boundary](#input\_role\_permissions\_boundary) | Permissions boundary to apply to the Step Function execution role | `string` | n/a | yes |
| <a name="input_sfn_ticket_data_name"></a> [sfn\_ticket\_data\_name](#input\_sfn\_ticket\_data\_name) | Name of the Step Function for the ticket data workflow | `string` | n/a | yes |
| <a name="input_ssm_params"></a> [ssm\_params](#input\_ssm\_params) | SSM parameters used to configure workflow customisations | <pre>object({<br/>    exclude_requesters = string<br/>    exclude_subjects   = string<br/>    group_mappings     = string<br/>  })</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_step_function_arn"></a> [step\_function\_arn](#output\_step\_function\_arn) | ARN of the Step Function |
<!-- END_TF_DOCS -->