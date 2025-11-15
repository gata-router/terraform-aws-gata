# OIDC Pipeline

Configures the resources required for GitHub Actions to deploy a container images using OIDC. It also grants permissions to the pipeline to update the value of the SSM Parameter used to track the release tag for the image.

To use this module you must configure the [GitHub IdP in IAM](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/#:~:text=Step%201:%20Create%20an%20OIDC%20provider%20in%20your%20account). Managing the IdP is not a responsibility of this module or Gata.

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
| [aws_iam_policy.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.ecr_push](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.github_oidc_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ecr_repo"></a> [ecr\_repo](#input\_ecr\_repo) | ARN of the ECR repository. | `string` | n/a | yes |
| <a name="input_github_env"></a> [github\_env](#input\_github\_env) | The name of the GitHub environment used when running the deployment. | `string` | n/a | yes |
| <a name="input_github_oidc_provider_arn"></a> [github\_oidc\_provider\_arn](#input\_github\_oidc\_provider\_arn) | ARN of the existing GitHub OIDC provider in AWS IAM. Leave empty to create a new provider. | `string` | `""` | no |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | The GitHub organization for the repository. | `string` | n/a | yes |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | The name of the GitHub repository. | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The ARN of the KMS key to use for encrypting the ECR images at rest. | `string` | n/a | yes |
| <a name="input_role_namespace"></a> [role\_namespace](#input\_role\_namespace) | Namespace/prefix for the IAM roles. Prepended to the application name. | `string` | n/a | yes |
| <a name="input_role_permissions_boundary"></a> [role\_permissions\_boundary](#input\_role\_permissions\_boundary) | Permissions boundary to apply to IAM roles | `string` | n/a | yes |
| <a name="input_ssm_param_arn"></a> [ssm\_param\_arn](#input\_ssm\_param\_arn) | The ARN of the SSM parameter to use for storing the image version. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | n/a |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | n/a |
<!-- END_TF_DOCS -->