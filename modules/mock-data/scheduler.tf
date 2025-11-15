resource "aws_scheduler_schedule" "hourly_ticket_scheduler" {
  count = var.enable_hourly_tickets ? 1 : 0

  name        = "${var.application_name}-${var.tags["environment"]}-mock-data-hourly-tickets"
  description = "Create mock tickets every hour"

  kms_key_arn = var.kms_key_arn

  schedule_expression = "rate(1 hour)"

  flexible_time_window {
    mode = "FLEXIBLE"

    maximum_window_in_minutes = 10
  }

  target {
    arn = aws_sfn_state_machine.create.arn

    dead_letter_config {
      arn = aws_sqs_queue.dlq_hourly[0].arn
    }

    input = jsonencode({ num_tickets = 1 })

    role_arn = aws_iam_role.hourly_ticket_scheduler[0].arn

    retry_policy {
      maximum_event_age_in_seconds = 600

      maximum_retry_attempts = 1
    }
  }
}
