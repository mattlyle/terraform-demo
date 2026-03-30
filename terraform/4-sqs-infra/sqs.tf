# Dead-letter queue — catches messages that fail processing 3 times.
resource "aws_sqs_queue" "dead_letter_queue" {
  name                      = "${var.project_name}-jobs-dead-letter-queue"
  message_retention_seconds = 3600 # 1 hour — demo only

  tags = local.common_tags
}

# Main job queue consumed by the backend-worker.
resource "aws_sqs_queue" "jobs" {
  name = "${var.project_name}-jobs"

  # Visibility timeout must exceed the maximum job duration so a slow worker
  # doesn't cause duplicate processing. Set to 60s (jobs are capped at ~15s).
  visibility_timeout_seconds = 60

  message_retention_seconds = 3600 # 1 hour — demo only

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 3
  })

  tags = local.common_tags
}
