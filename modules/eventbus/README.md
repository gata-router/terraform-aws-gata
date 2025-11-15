# Gata EventBus

This component sets up an [Amazon EventBridge](https://docs.aws.amazon.com/eventbridge/) event bus instance for handling [webhook events from Zendesk](https://developer.zendesk.com/documentation/webhooks/). A Lambda function URL receives the events via a webhook before pushing them onto the bus.

## Configure Credentials

We need to ensure the credentials are configured so the webhook handler can receive the events.

### SSM Parameters

Ee need to set the credentials for the webhook in SSM Parameter Store with the following steps:

1. Get the SSM Parameter name. It is naming using the `/<namespace>/<environment>/webhook-creds` pattern.
2. Go to the [SSM Parameters in the AWS Console](https://console.aws.amazon.com/systems-manager/parameters/).
3. Click on your parameter.
4. Click the edit button in the top tight corner.
5. Click into the edit field of the form.
6. Update the JSON object with your credentials. Make then strong.
7. Click the save changes button.

## Zendesk Configuration

The webhook handler needs to be configured in Zendesk.

Follow these steps to create the webhook:

1. Get the URL of the webhook URL. This can be found in the Terraform output or in the Lambda function configuration in the AWS Console.
2. Get the webhook credentials from SSM Parameter store.
3. In Zendesk go to Admin > Apps and Integrations > Webhooks > Click the "Create Webhook button" (URL: /admin/apps-integrations/webhooks/webhooks/add).
4. Click the "Zendesk events" option.
5. Select Ticket events > Any ticket events from the event type drop down.
6. Click Next
7. Populate the fields as follows:
  * **Name:** Gata
  * **Description:** Send events to the Gata ticket router
  * **Endpoint URL:** The webhook URL from step 1
  * **Request method:** POST
  * **Request format:** JSON
  * **Authentication:** Basic Authentication
  * **Username:** Copy from values used in Configure Credentialsa section above
  * **Password:** Copy from values used in Configure Credentialsa section above
  * **Add header:** Skip
8. Click the "Test webhook" button
9. Leave the defaults and click "Send test".
10. You should receive a "400 Bad Request" response with an "Invalid webhook data structure" message in the JSON body. This is expected and confirms everything is working expected.
11. Click the "Create webhook" button to create the webhook.

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
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.0.0, < 3.0.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.AWSXRayDaemonWriteAccess](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function_url.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url) | resource |
| [aws_lambda_permission.furl_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.AWSXRayDaemonWriteAccess](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name for the application. Used to prefix resources provisioned by this module. | `string` | n/a | yes |
| <a name="input_eventbus_name"></a> [eventbus\_name](#input\_eventbus\_name) | Name of the EventBridge event bus | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of the KMS key to use for encryption | `string` | n/a | yes |
| <a name="input_lambda_powertools_arn"></a> [lambda\_powertools\_arn](#input\_lambda\_powertools\_arn) | ARN of the Lambda Powertools layer | `string` | n/a | yes |
| <a name="input_python_version"></a> [python\_version](#input\_python\_version) | Python version to use for the Lambda function | `string` | n/a | yes |
| <a name="input_role_namespace"></a> [role\_namespace](#input\_role\_namespace) | Namespace/prefix for the Lambda execution role | `string` | n/a | yes |
| <a name="input_role_permissions_boundary"></a> [role\_permissions\_boundary](#input\_role\_permissions\_boundary) | Permissions boundary to apply to the Lambda execution role | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_webhook_creds"></a> [webhook\_creds](#input\_webhook\_creds) | Name of the SSM parameter containing the webhook credentials | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARNs of the lambda function |
| <a name="output_lambda_function_url"></a> [lambda\_function\_url](#output\_lambda\_function\_url) | URL of the lambda function |
| <a name="output_lambda_role_arn"></a> [lambda\_role\_arn](#output\_lambda\_role\_arn) | ARNs of the lambda role |
<!-- END_TF_DOCS -->