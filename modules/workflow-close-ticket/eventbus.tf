# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

resource "aws_cloudwatch_event_rule" "solved_ticket" {
  name           = "gata-solved-ticket"
  description    = "Zendesk ticket solved"
  event_bus_name = var.eventbus

  event_pattern = jsonencode({
    source = [
      "zendesk.com"
    ]
    detail-type = [
      "ticket.status_changed"
    ]
    detail = {
      "event" = {
        "current" = [
          "SOLVED"
        ]
      }
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "record" {
  rule           = aws_cloudwatch_event_rule.solved_ticket.name
  target_id      = "${aws_cloudwatch_event_rule.solved_ticket.name}-record"
  event_bus_name = aws_cloudwatch_event_rule.solved_ticket.event_bus_name

  arn      = aws_sfn_state_machine.record.arn
  role_arn = aws_iam_role.eb_solved_ticket.arn

  input_path = "$.detail"
}

resource "aws_cloudwatch_event_target" "summary" {
  rule           = aws_cloudwatch_event_rule.solved_ticket.name
  target_id      = "${aws_cloudwatch_event_rule.solved_ticket.name}-summary"
  event_bus_name = aws_cloudwatch_event_rule.solved_ticket.event_bus_name

  arn      = aws_sfn_state_machine.summary.arn
  role_arn = aws_iam_role.eb_solved_ticket.arn

  input_path = "$.detail"
}

data "aws_iam_policy_document" "eb_solved_ticket" {
  statement {
    effect = "Allow"

    actions = [
      "states:StartExecution",
    ]

    resources = [
      aws_sfn_state_machine.record.arn,
      aws_sfn_state_machine.summary.arn,
    ]
  }
}

resource "aws_iam_policy" "eb_solved_ticket" {
  name        = aws_iam_role.eb_solved_ticket.name
  description = "Push events to solved ticket sfn"
  policy      = data.aws_iam_policy_document.eb_solved_ticket.json
}

data "aws_iam_policy_document" "eb_solved_ticket_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eb_solved_ticket" {
  name                 = local.eb_role_name
  assume_role_policy   = data.aws_iam_policy_document.eb_solved_ticket_assume.json
  permissions_boundary = var.role_permissions_boundary

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eb_solved_ticket" {
  role       = aws_iam_role.eb_solved_ticket.name
  policy_arn = aws_iam_policy.eb_solved_ticket.arn
}
