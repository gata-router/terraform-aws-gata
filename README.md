# Gata Ticket Router

Gata triages and routes Zendesk support tickets. Rather than using humans to do this work, Gata used machine learning and LLMs to analyse the tickets. They are prioritised based on content and assigned to the appropriate group. All of the tooling runs on AWS, with the only data exchange occurring with Zendesk.

Operational costs vary, with per ticket costs reducing with greater volume. The target price is 0.02-0.05USD per ticket. This includes all AWS infrastructure and operations such as weekly training, routing, prioritisation and summarisation. 

The ideal user of Gata is a team with at least 1000 tickets per month where 80% or more are not classified. The model performs well with both balanced and uneven distribution of ticket categories.

## Quick Start

If you want to skip the 🧇, [jump straight to the quick start](examples/quickstart/README.md) to install and start using Gata.

## Models

Gata uses the most appropriate model for each task. All models run in your AWS account.

Ticket are routed using BERT. The model is fine tuned on your historic ticket data. It uses group assignment from closed tickets the label for fine tuning.

Prioritisation is handled using the Amazon Nova Micro model. This model is very cost effective for this task.

When a ticket is closed Amazon Nova Lite summarises the underlying issue and actions taken.

## Dependencies

Gata is built on several other projects.

PicoFun provides the Zendesk API clients. This adds a lot of small Lambda functions to your environment

EventBus++ provides the EventBridge event bus implementation.

3 container images are used in the fine tuning workflow. One for preparing the data, one for fine tuning the model and a final one for running the model.

## Quota Increases

In order to run Gata you need to request the following AWS quota increases:

* [SageMaker: Maximum total concurrency that can be allocated across all serverless endpoints](https://us-east-1.console.aws.amazon.com/servicequotas/home/services/sagemaker/quotas/L-96300102) - 50
* [SageMaker: ml.g6.xlarge for spot training job usage](https://us-east-1.console.aws.amazon.com/servicequotas/home/services/sagemaker/quotas/L-A886A53A) - 2
* [SageMaker: ml.g6.xlarge for training job usage](https://us-east-1.console.aws.amazon.com/servicequotas/home/services/sagemaker/quotas/L-56AE9D73) - 2

It can take several days for these increases to be processed. 

AWS no longer requires you to request access to foundation models. Nova Micro and Lite should be enabled in your account.

## Disclaimer

Gata is offered as is. You are responsible for reviewing the code and determining if it appropriate for your use case. You are solely responsible for any costs incurred from the use of any Gata components.

No representations are made in relation to the ongoing maintenance of this project. You are responsible for maintaining Gata in your environment.

## FAQ

### Project

#### Is Gata self hosted?

Yes! Gata runs in your own AWS account.

#### Can you host it for me?

Probably not, but I can [help you deploy Gata in your own AWS environment](https://davehall.com.au/contact)

#### Do you offer support?

Yes! If you experience a problem, raise an issue.

If you need support for your business or help deploying Gata, please [contact me](https://davehall.com.au/contact).

#### Does Gata support Jira / ServiceNow / Intercom / Help Scout / etc?

Gata currently only supports Zendesk tickets. Many of the components could be reused to build a similar system for another support ticket platform.

#### How does Gata learn from reassigned tickets?

Gata is trained using the group assigned when the ticket is closed. Each week a new model is trained using the last 3 months of closed tickets. This means it doesn't take long for the model to learn from its mistakes.

#### When will you implement feature X?

Not sure. I built this for a particular use case. It worked. I now use it to explore AI/ML/GenAI. Rather than raising a pull request, start a discussion by raising an issue.

If you want a particular feature built for your business, [contact me](https://davehall.com.au/contact).

#### What next is on the roadmap?

I don't have a roadmap. This project is my playground. I build features when I want to explore next ideas.

#### Can I use this for X?

So long as you comply with the [license](LICENSE.txt) you can use this however you want. The limit is your imagination 🤯

### Technical

#### Why won't you fix the "Deprecated attribute" error for `data.aws_region.current.name`?

We support both versions 5 and 6 of the AWS Terraform provider. Version 6 renamed the `name` attribute to `region`. This will be fixed once we drop support for Terraform 6.

#### Why do you have so many external dependencies?

Many of the dependencies are other projects I maintain. I don't want to reinvent the wheel.

#### Can I change X so it does Y?

Sure, all the code is there. Use it how you want.

#### You do some crazy stuff in Step Functions!

That's a statement, not a question, but I'll take it as a compliment.

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.31.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_db"></a> [db](#module\_db) | ./modules/db | n/a |
| <a name="module_ecr"></a> [ecr](#module\_ecr) | ./modules/ecr | n/a |
| <a name="module_ecr_github_actions"></a> [ecr\_github\_actions](#module\_ecr\_github\_actions) | ./modules/oidc-pipeline | n/a |
| <a name="module_eventbus_gata"></a> [eventbus\_gata](#module\_eventbus\_gata) | git::ssh://git@github.com/proactiveops/eventbus | a2ae81c |
| <a name="module_eventbus_handlers"></a> [eventbus\_handlers](#module\_eventbus\_handlers) | ./modules/eventbus | n/a |
| <a name="module_eventbus_zendesk"></a> [eventbus\_zendesk](#module\_eventbus\_zendesk) | git::ssh://git@github.com/proactiveops/eventbus | a2ae81c |
| <a name="module_eventbus_zendesk_dlq"></a> [eventbus\_zendesk\_dlq](#module\_eventbus\_zendesk\_dlq) | git::ssh://git@github.com/proactiveops/eventbus//modules/dlq | a2ae81c |
| <a name="module_finetune_workflow"></a> [finetune\_workflow](#module\_finetune\_workflow) | ./modules/finetune-workflow | n/a |
| <a name="module_firehose"></a> [firehose](#module\_firehose) | ./modules/firehose | n/a |
| <a name="module_mock_data"></a> [mock\_data](#module\_mock\_data) | ./modules/mock-data | n/a |
| <a name="module_mock_router"></a> [mock\_router](#module\_mock\_router) | ./modules/mock-ticket-update | n/a |
| <a name="module_prepare_text"></a> [prepare\_text](#module\_prepare\_text) | ./modules/prepare-text | n/a |
| <a name="module_s3"></a> [s3](#module\_s3) | ./modules/s3 | n/a |
| <a name="module_workflow_assigned_ticket"></a> [workflow\_assigned\_ticket](#module\_workflow\_assigned\_ticket) | ./modules/workflow-assigned-ticket | n/a |
| <a name="module_workflow_close_ticket"></a> [workflow\_close\_ticket](#module\_workflow\_close\_ticket) | ./modules/workflow-close-ticket | n/a |
| <a name="module_workflow_finetune_general"></a> [workflow\_finetune\_general](#module\_workflow\_finetune\_general) | ./modules/model-workflow | n/a |
| <a name="module_workflow_finetune_low_volume"></a> [workflow\_finetune\_low\_volume](#module\_workflow\_finetune\_low\_volume) | ./modules/model-workflow | n/a |
| <a name="module_workflow_new_ticket"></a> [workflow\_new\_ticket](#module\_workflow\_new\_ticket) | ./modules/workflow-new-ticket | n/a |
| <a name="module_workflow_ticket_data"></a> [workflow\_ticket\_data](#module\_workflow\_ticket\_data) | ./modules/workflow-ticket-data | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_ssm_parameter.filters](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.images](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.webhook_creds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.permissions_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_roles.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_roles) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.lambda_powertools_layer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_role"></a> [admin\_role](#input\_admin\_role) | Details of the admin role for managing sensitive resources. The path is only needed if using a SSO role. | <pre>object({<br/>    name = string<br/>    path = optional(string, "/")<br/>  })</pre> | n/a | yes |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name for the application. Used to prefix resources provisioned by this module. | `string` | `"gata"` | no |
| <a name="input_db_scaling"></a> [db\_scaling](#input\_db\_scaling) | The scaling configuration for the database. | <pre>object({<br/>    min = optional(number, 0)<br/>    max = optional(number, 2)<br/>  })</pre> | n/a | yes |
| <a name="input_enable_firehose"></a> [enable\_firehose](#input\_enable\_firehose) | Enable the Firehose delivery stream for writing tickets events to S3. | `bool` | `true` | no |
| <a name="input_enable_mock_data"></a> [enable\_mock\_data](#input\_enable\_mock\_data) | Enable the mock data generator resources. Use this to generate and load sample ticket data. Do not use on production systems. | `bool` | `false` | no |
| <a name="input_enable_test_tickets"></a> [enable\_test\_tickets](#input\_enable\_test\_tickets) | Generate a test ticket once an hour. Provides sample data for testing and system validation. Do not use on production systems. | `bool` | `false` | no |
| <a name="input_finetune_max_exec"></a> [finetune\_max\_exec](#input\_finetune\_max\_exec) | Maximum execution time for the fine-tuning job | `number` | `7200` | no |
| <a name="input_github_oidc_provider_arn"></a> [github\_oidc\_provider\_arn](#input\_github\_oidc\_provider\_arn) | ARN of the existing GitHub OIDC provider in AWS IAM. Leave empty to create a new provider. | `string` | `""` | no |
| <a name="input_github_pipeline_config"></a> [github\_pipeline\_config](#input\_github\_pipeline\_config) | Configuration for the GitHub Actions pipelines for ECR images. Leave empty to disable. If environment isn't set, the pipeline will allow any tags to push images. | <pre>object({<br/>    env         = optional(string)<br/>    org         = string<br/>    repo_prefix = optional(string, "")<br/>  })</pre> | `null` | no |
| <a name="input_lambda_function_arns"></a> [lambda\_function\_arns](#input\_lambda\_function\_arns) | ARNs for Lambda functions invoked in the workflows | <pre>object({<br/>    redact          = string               # From proactiveops/util-fns<br/>    ticket_get      = string               # "arn:aws:lambda:us-east-1:012345678910:function:zendesk_get_api_v2_tickets_ticket_id",<br/>    ticket_comments = string               # "arn:aws:lambda:us-east-1:012345678910:function:zendesk_get_api_v2_tickets_ticket_id_comments",<br/>    ticket_create   = string               # "arn:aws:lambda:us-east-1:012345678910:function:zendesk_post_api_v2_tickets",<br/>    ticket_update   = optional(string, "") # If left empty, noop function will be used # "arn:aws:lambda:us-east-1:012345678910:function:zendesk_put_api_v2_tickets_ticket_id",<br/>    user_get        = string               # "arn:aws:lambda:us-east-1:012345678910:function:zendesk_get_api_v2_users_user_id",<br/>  })</pre> | n/a | yes |
| <a name="input_lambda_powertools_version"></a> [lambda\_powertools\_version](#input\_lambda\_powertools\_version) | The version of the AWS Lambda Powertools Lambda layer. Set to 0 if you want to always use the latest version. | `number` | `0` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain logs in CloudWatch Logs | `number` | `30` | no |
| <a name="input_logging_bucket"></a> [logging\_bucket](#input\_logging\_bucket) | Bucket to store S3 logs. Must be in the same region and account. Leave empty to disable. | `string` | `""` | no |
| <a name="input_low_volume_fallback_label"></a> [low\_volume\_fallback\_label](#input\_low\_volume\_fallback\_label) | Label to use when there is insufficient low volume ticket data to train a model. | `number` | n/a | yes |
| <a name="input_override_image_tags"></a> [override\_image\_tags](#input\_override\_image\_tags) | Versions of the ECR images to use. Leave empty to use the latest image available. During initial setup, set the values to ':latest'. | <pre>object({<br/>    data_prep = optional(string, null)<br/>    finetune  = optional(string, null)<br/>    inference = optional(string, null)<br/>  })</pre> | `{}` | no |
| <a name="input_role_namespace"></a> [role\_namespace](#input\_role\_namespace) | Namespace/prefix for IAM roles. Prepended to the application name. | `string` | `""` | no |
| <a name="input_role_permissions_boundary"></a> [role\_permissions\_boundary](#input\_role\_permissions\_boundary) | Permissions boundary to apply to IAM roles | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs to use for the database cluster | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | n/a | yes |
| <a name="input_train_on_spot"></a> [train\_on\_spot](#input\_train\_on\_spot) | Use spot instances for fine tuning the models. | `bool` | `true` | no |
| <a name="input_vpc_endpoints"></a> [vpc\_endpoints](#input\_vpc\_endpoints) | Security groups for VPC endpoints used for accessing AWS services. Format <service-name> = <security-group-id>. Replace . in the service name with -. If endpoint not provided, egress to 0.0.0.0/0 is allowed. | `map(string)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
