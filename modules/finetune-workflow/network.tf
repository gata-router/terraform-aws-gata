# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

data "aws_subnet" "this" {
  for_each = toset(var.subnet_ids)

  id = each.value
}

locals {
  vpc_id = [for subnet in data.aws_subnet.this : subnet][0].vpc_id
}

data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

resource "aws_security_group" "this" {
  name        = local.data_prep_namespace
  description = "Data Prep ECS task"
  vpc_id      = local.vpc_id

  tags = merge(var.tags, {
    Name = local.data_prep_namespace
  })
}

resource "aws_vpc_security_group_egress_rule" "egress_https_all" {
  count = length(var.vpc_endpoint_security_groups) == 0 ? 1 : 0

  security_group_id = aws_security_group.this.id
  description       = "HTTPS open"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  #trivy:ignore:avd-aws-0104 We need to allow access to the internet for now
  cidr_ipv4 = "0.0.0.0/0"
}


resource "aws_vpc_security_group_egress_rule" "egress_https" {
  for_each = { for k, v in var.vpc_endpoint_security_groups : k => v if contains(["ecr-api", "ecr-dkr", "logs", "rds-data", "secretsmanager", "ssm"], k) }

  security_group_id = aws_security_group.this.id
  description       = "to ${each.key}"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  referenced_security_group_id = each.value
}

resource "aws_vpc_security_group_egress_rule" "egress_https_s3" {
  security_group_id = aws_security_group.this.id
  description       = "to S3"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  prefix_list_id = contains(keys(var.vpc_endpoint_security_groups), "s3") ? var.vpc_endpoint_security_groups["s3"] : data.aws_ec2_managed_prefix_list.s3.id
}
