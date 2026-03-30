# ── VPC Flow Logs ─────────────────────────────────────────────────────────────
# Captures every accepted and rejected flow through the VPC.
# Logs land in CloudWatch Logs Insights — queryable in real time during the demo.
#
# Demo query to paste into CloudWatch Logs Insights:
#   fields @timestamp, srcAddr, dstAddr, srcPort, dstPort, protocol, action, bytes
#   | filter action = "REJECT"
#   | sort @timestamp desc
#   | limit 50

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/vpc/flow-logs/${var.project_name}"
  retention_in_days = 7 # short retention — this is a demo

  tags = local.common_tags
}

# IAM role that allows the VPC Flow Logs service to write to CloudWatch
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "write-to-cloudwatch"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
    }]
  })
}

resource "aws_flow_log" "vpc" {
  vpc_id          = module.vpc.vpc_id
  traffic_type    = "ALL" # capture ACCEPT + REJECT — more interesting for the demo
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn

  # Custom format adds direction, instance, and AZ — the default format omits these
  log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${flow-direction} $${az-id}"

  tags = local.common_tags
}
