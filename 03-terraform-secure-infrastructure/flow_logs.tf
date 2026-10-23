# Allow the VPC Flow Logs service to assume its delivery role.
data "aws_iam_policy_document" "flow_logs_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

# Dedicated role for publishing VPC Flow Logs.
resource "aws_iam_role" "flow_logs" {
  name               = "cloudguard-flowlogs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_trust.json
}

# Destination for network traffic records.
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/cloudguard/vpc-flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudguard_flow_logs.arn

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
  }
}

# Permit the delivery role to publish to the designated log group.
resource "aws_iam_role_policy" "flow_logs_publish" {
  name = "cloudguard-flowlogs-publish"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      },
      {
        Effect   = "Allow"
        Action   = "logs:DescribeLogGroups"
        Resource = "*"
      }
    ]
  })
}

# Enable VPC Flow Logs and send all traffic metadata to CloudWatch.
resource "aws_flow_log" "cloudguard_vpc" {
  vpc_id               = aws_vpc.cloudguard.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn         = aws_iam_role.flow_logs.arn

  depends_on = [
    aws_iam_role_policy.flow_logs_publish
  ]
}
