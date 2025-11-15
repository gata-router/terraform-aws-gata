# Amazon Aurora Serverless Database for Gata

This module provisions an Amazon Aurora Serverles v2 PostgreSQL database for Gata to use to track tickets.

We use serverless mode as the traffic is likely to be uneven and unpredictable. Feel free to swap this out for a provisioned instance if your ticket volume justifies it.

We use a PostgreSQL primarily as a vector store. It also avoids the need for configuring multiple global secondary indexes on DynamoDB.

# Generated Docs

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
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_rds_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_secretsmanager_secret.db_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.db_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_serverlessapplicationrepository_cloudformation_stack.rotate_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/serverlessapplicationrepository_cloudformation_stack) | resource |
| [aws_vpc_security_group_egress_rule.db_to_data_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.data_api_vpce_to_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [terraform_data.db_schema](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.db_user](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.secret_db_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_serverlessapplicationrepository_application.rotate_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/serverlessapplicationrepository_application) | data source |
| [aws_subnet.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_role_arn"></a> [admin\_role\_arn](#input\_admin\_role\_arn) | ARN of the admin role for managing sensitive resources. | `string` | n/a | yes |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name for the application. Used to prefix resources provisioned by this module. | `string` | `"gata"` | no |
| <a name="input_data_api_vpce_security_group"></a> [data\_api\_vpce\_security\_group](#input\_data\_api\_vpce\_security\_group) | ID of the security group for the VPC endpoint for the RDS data API | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of the KMS key to use for encryption | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain logs in CloudWatch Logs | `number` | n/a | yes |
| <a name="input_scaling"></a> [scaling](#input\_scaling) | The scaling configuration for the database. | <pre>object({<br/>    min = number<br/>    max = number<br/>  })</pre> | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs to use for the database cluster | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ARN of the database cluster |
| <a name="output_db_endpoints"></a> [db\_endpoints](#output\_db\_endpoints) | Endpoints for the database cluster |
| <a name="output_db_name"></a> [db\_name](#output\_db\_name) | Name of the default database |
| <a name="output_db_security_group"></a> [db\_security\_group](#output\_db\_security\_group) | Security group for the database cluster |
| <a name="output_secrets"></a> [secrets](#output\_secrets) | ARN of the secret for the admin user |
<!-- END_TF_DOCS -->