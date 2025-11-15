# GATA Quick Start

This is a short guide to running GATA in your AWS account. It assumes that you are experienced with Terraform, Docker, Python and AWS.

**GATA has only been tested in the North Virginia / us-east-1 region. Other regions are not supported at this time.***

## Prerequisites

To install and run the quick start you need the following tools installed:

* Terraform
* Python 3.13
* `uv` 
* docker

This project has only been tested on MacOS and Linux.

You will need an AWS account with at least 3 private subsets configured. You must have VPC endpoints or a NAT Gateway provisioned and the route table configured for the private subsets.

In order to run GATA in your AWS account, you must [request SageMaker quota increases](../../README.md#quota-increases). You must wait for this to be approved before continuing.

You need to generate the Zendesk client Lambda using the [picofun example project](https://github.com/proactiveops/picofun/tree/main/example). Perform the following steps:

1. Clone the picofun repository outside your GATA directory: `git clone git@github.com:proactiveops/picofun.git`
2. Change into the picofun directory: `cd picofun`
3. Install the dependencies: `uv sync`
4. Edit `example/picofun.toml` and set your Zendesk subdomain value
5. Generate the Zendesk client: `uv run picofun --config-file example/picofun.toml zendesk https://developer.zendesk.com/zendesk/oas.yaml`
6. Copy the extra Terraform configuration: `cp example/extra.tf output/`
7. Create the module directory in quickstart: `mkdir -p examples/quickstart/modules/`
8. Copy the generated module to quickstart: `cp -a output/ examples/quickstart/modules/picofun-zendesk`

Now you're set to install the quickstart

## Steps

1. [Configure the variable for your environment in `main.tf`](main.tf)
2. Configure AWS credentials for your target account. I recommend environment variables from an identity centre user with admin privileges.
3. Deploy everything using `terraform deploy`
4. Build and push the docker images for [data prep](https://github.com/gata-router/gata-data-prep), [finetuning](https://github.com/gata-router/gata-finetune), and [inference](https://github.com/gata-router/gata-inference). The image tag should use the `YYYYMMDDHH` format.
5. Update the SSM Parameters for each of the images so the workflow uses the correct version. The path for the parameters is `/<namesapce>/<environment>/image/version-<image>` and the value is `:<YYYYMMDDHH>` that matches the image tag.
6. Load your Zendesk API crendtials into SSM Parameters. The path of the parameter is `/picofun/zendesk/credentials-http`. Use the `{"username":"<USER-EMAIL>/token","password":"<PASSWORD>"}` format.
7. [Backfill your closed ticket data](../../scripts/backfill/README.md).
8. Run gata finetune [workflow in Step Functions](https://us-east-1.console.aws.amazon.com/states/home?region=us-east-1#/statemachines), with the payload `{"BatchID": "YYYYMMDDHH"}` (replace the values with the current date and hour)
9. Test processing tickets as expected
10. Once you're happy with how the router is running in reporting mode, uncomment the `lambda_function_arns.ticket_update` variable to route tickets

That's it! Enjoy.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.20.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gata"></a> [gata](#module\_gata) | ../../ | n/a |
| <a name="module_picofun_zendesk"></a> [picofun\_zendesk](#module\_picofun\_zendesk) | ./modules/picofun-zendesk | n/a |
| <a name="module_util_fns"></a> [util\_fns](#module\_util\_fns) | github.com/proactiveops/util-fns | 9b52f97 |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->