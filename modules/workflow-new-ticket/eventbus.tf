# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

resource "aws_cloudwatch_event_rule" "new_ticket" {
  name           = "gata-new-ticket"
  description    = "Zendesk ticket created"
  event_bus_name = var.eventbus

  event_pattern = jsonencode({
    source = [
      "zendesk.com"
    ]
    detail-type = [
      "ticket.created"
    ]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "new_ticket" {
  rule           = aws_cloudwatch_event_rule.new_ticket.name
  target_id      = aws_cloudwatch_event_rule.new_ticket.name
  event_bus_name = aws_cloudwatch_event_rule.new_ticket.event_bus_name

  arn      = aws_sfn_state_machine.this.arn
  role_arn = aws_iam_role.eb_new_ticket.arn

  input_path = "$.detail"
}

data "aws_iam_policy_document" "eb_new_ticket" {
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

resource "aws_iam_policy" "eb_new_ticket" {
  name        = aws_iam_role.eb_new_ticket.name
  description = "Push events to closed ticket sfn"
  policy      = data.aws_iam_policy_document.eb_new_ticket.json
}

data "aws_iam_policy_document" "eb_new_ticket_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eb_new_ticket" {
  name                 = local.eb_role_name
  assume_role_policy   = data.aws_iam_policy_document.eb_new_ticket_assume.json
  permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eb_new_ticket" {
  role       = aws_iam_role.eb_new_ticket.name
  policy_arn = aws_iam_policy.eb_new_ticket.arn
}
