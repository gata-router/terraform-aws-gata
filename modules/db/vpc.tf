# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {
  vpc_id = [for s in data.aws_subnet.db : s][0].vpc_id
}

data "aws_subnet" "db" {
  for_each = toset(var.subnet_ids)

  id = each.value
}

resource "aws_security_group" "db" {
  name = local.db_cluster_name

  description = "${local.db_cluster_name} postgresql database"

  vpc_id = local.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "db_to_data_api" {
  security_group_id = aws_security_group.db.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "DB to Data API"

  # trivy:ignore:AVD-AWS-0104 If there isn't a VPCe we need to allow all outbound traffic to 443/tcp.
  cidr_ipv4 = var.data_api_vpce_security_group == "" ? "0.0.0.0/0" : null

  referenced_security_group_id = var.data_api_vpce_security_group != "" ? var.data_api_vpce_security_group : null
}

resource "aws_vpc_security_group_ingress_rule" "data_api_vpce_to_db" {
  count = var.data_api_vpce_security_group != "" ? 1 : 0

  security_group_id = var.data_api_vpce_security_group

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.db.id
}
/*
resource "aws_security_group" "secret_user_lambda" {
  name = local.db_cluster_name

  description = "${local.db_cluster_name} db user secret rotation lambda"

  vpc_id = local.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "secret_lambda_to_data_api" {
  security_group_id = aws_security_group.secret_user_lambda.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  # If there isn't a VPCe we need to allow all outbound traffic to 443/tcp.
  cidr_ipv4 = var.data_api_vpce_security_group == "" ? "0.0.0.0/0" : null

  referenced_security_group_id = var.data_api_vpce_security_group != "" ? var.data_api_vpce_security_group : null
}

resource "aws_vpc_security_group_ingress_rule" "data_api_vpce_from_secret_lambda" {
  count = var.data_api_vpce_security_group != "" ? 1 : 0

  security_group_id = var.data_api_vpce_security_group

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.lambda.id
}
*/
