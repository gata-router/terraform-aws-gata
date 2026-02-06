# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

data "aws_iam_policy_document" "events_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_event_rule" "assigned_ticket" {
  name           = "gata-assigned-ticket"
  description    = "Zendesk ticket assigned to group"
  event_bus_name = var.eventbus

  event_pattern = jsonencode({
    source = [
      "zendesk.com"
    ]
    "detail-type" = [
      "ticket.group_assignment_changed"
    ]
    detail = {
      event = {
        previous = [null]
      }
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "assigned_ticket" {
  rule           = aws_cloudwatch_event_rule.assigned_ticket.name
  target_id      = aws_cloudwatch_event_rule.assigned_ticket.name
  event_bus_name = aws_cloudwatch_event_rule.assigned_ticket.event_bus_name

  arn      = aws_sfn_state_machine.this.arn
  role_arn = aws_iam_role.eb_assigned_ticket.arn

  input_path = "$.detail"
}

data "aws_iam_policy_document" "eb_assigned_ticket" {
  statement {
    effect = "Allow"

    actions = [
      "states:StartExecution",
    ]

    resources = [
      aws_sfn_state_machine.this.arn,
    ]
  }
}

resource "aws_iam_policy" "eb_assigned_ticket" {
  name        = aws_iam_role.eb_assigned_ticket.name
  description = "Push events to ticket assigned sfn"
  policy      = data.aws_iam_policy_document.eb_assigned_ticket.json
}

resource "aws_iam_role" "eb_assigned_ticket" {
  name                 = local.eb_role_name
  assume_role_policy   = data.aws_iam_policy_document.events_assume.json
  permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eb_assigned_ticket" {
  role       = aws_iam_role.eb_assigned_ticket.name
  policy_arn = aws_iam_policy.eb_assigned_ticket.arn
}
