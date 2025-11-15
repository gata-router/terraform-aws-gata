# ECR Repository

This module provisions an ECR Repository for storing a container image. Nothing fancy, just an immutable container registry.

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
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecr_image.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_image) | data source |
| [aws_iam_policy_document.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.gata](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_ssm_parameter.image_ref](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_role_arn"></a> [admin\_role\_arn](#input\_admin\_role\_arn) | ARN of the IAM role to use for admin access | `string` | n/a | yes |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Tag of the image to use. If not set, the value will be pulled from SSM Params. | `string` | n/a | yes |
| <a name="input_image_tag_param_name"></a> [image\_tag\_param\_name](#input\_image\_tag\_param\_name) | Name of the SSM Parameter to use to get the image tag if image\_tag is not set | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The ARN of the KMS key to use for encryption at rest | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the ECR repository | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_image_url"></a> [image\_url](#output\_image\_url) | Full URL of the ECR image including tag or digest |
| <a name="output_repo_arn"></a> [repo\_arn](#output\_repo\_arn) | ARN of the ECR repository |
| <a name="output_repo_url"></a> [repo\_url](#output\_repo\_url) | URL of the ECR repository |
<!-- END_TF_DOCS -->