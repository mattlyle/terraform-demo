output "sqs_queue_url" {
  description = "SQS jobs queue URL — injected as SQS_QUEUE_URL env var into api-server and backend-worker"
  value       = aws_sqs_queue.jobs.url
}

output "sqs_queue_arn" {
  description = "SQS jobs queue ARN"
  value       = aws_sqs_queue.jobs.arn
}
