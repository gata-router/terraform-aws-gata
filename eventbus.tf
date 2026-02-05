# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {
  zendesk_bus_name = "zendesk"
}

module "eventbus_gata" {
  source = "git::https://github.com/proactiveops/eventbus?ref=a2ae81c" # main @ 20260125

  name = var.application_name

  allow_put_events_arns = [
    provider::aws::arn_build(
      data.aws_partition.current.partition,
      "events",
      data.aws_region.current.name,
      data.aws_caller_identity.current.account_id,
      "rule/${local.zendesk_bus_name}/*-${var.application_name}-${var.tags["environment"]}"
    )
  ]

  # TODO need to implement this in the eventbus++ module
  # role_namespace            = var.role_namespace
  # role_permissions_boundary = local.permissions_boundary

  enable_schema_discovery_registry = false

  tags = var.tags
}

module "eventbus_zendesk" {
  source = "git::https://github.com/proactiveops/eventbus?ref=a2ae81c" # main @ 20260125

  name = local.zendesk_bus_name

  cross_bus_rules = [
    {
      name    = "created-to-${var.application_name}-${var.tags["environment"]}"
      dlq_arn = module.eventbus_zendesk_dlq.arn

      target_arn = module.eventbus_gata.bus.arn

      pattern = jsonencode(
        {
          source = [
            "zendesk.com"
          ]

          "detail-type" = [
            "ticket.created",
          ]
        }
      )
    },
    {
      name    = "group-to-${var.application_name}-${var.tags["environment"]}"
      dlq_arn = module.eventbus_zendesk_dlq.arn

      target_arn = module.eventbus_gata.bus.arn

      pattern = jsonencode(
        {
          source = [
            "zendesk.com"
          ]

          "detail-type" = [
            "ticket.group_assignment_changed",
          ]

          detail = {
            event = {
              previous = [null]
            }
          }
        }
      )
    },
    {
      name    = "status-to-${var.application_name}-${var.tags["environment"]}"
      dlq_arn = module.eventbus_zendesk_dlq.arn

      target_arn = module.eventbus_gata.bus.arn

      pattern = jsonencode(
        {
          source = [
            "zendesk.com"
          ]

          "detail-type" = [
            "ticket.status_changed",
          ]

          detail = {
            event = {
              current = ["SOLVED"]
            }
          }
        }
      )
    },
  ]

  # role_namespace            = var.role_namespace
  # role_permissions_boundary = local.permissions_boundary

  tags = var.tags
}

module "eventbus_zendesk_dlq" {
  source = "git::https://@github.com/proactiveops/eventbus//modules/dlq?ref=a2ae81c" # main @ 20260125

  kms_key_id = aws_kms_key.this.arn

  queue_name = "dlq-zendesk-to-${var.application_name}-${var.tags["environment"]}"

  tags = var.tags
}

module "eventbus_handlers" {
  source = "./modules/eventbus"

  application_name = var.application_name

  eventbus_name = module.eventbus_zendesk.bus.name

  kms_key_arn = aws_kms_key.this.arn

  lambda_powertools_arn = local.lambda_powertools_arn

  python_version = local.python_version

  role_namespace            = var.role_namespace
  role_permissions_boundary = local.permissions_boundary

  webhook_creds = aws_ssm_parameter.webhook_creds.name

  tags = var.tags
}
