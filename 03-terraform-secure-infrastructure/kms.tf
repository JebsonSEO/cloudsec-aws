# Identify the AWS account for the KMS key policy.
data "aws_caller_identity" "current" {}

# Define the KMS key policy.
data "aws_iam_policy_document" "cloudguard_kms" {

  # Allow the AWS account to manage the KMS key through IAM permissions.
  statement {
    sid    = "EnableAccountIAMPermissions"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:PutKeyPolicy",
      "kms:EnableKeyRotation",
      "kms:GetKeyRotationStatus",
      "kms:ListResourceTags",
      "kms:TagResource",
      "kms:UntagResource"
    ]

    resources = ["*"]
  }

  # Allow account-level cryptographic operations on this key.
  statement {
    sid    = "AllowAccountCryptographicOperations"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*"
    ]

    resources = ["*"]
  }

  # Allow CloudWatch Logs to use this key for the designated log group.
  statement {
    sid    = "AllowCloudWatchLogsEncryption"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    # Restrict use of the key to the CloudGuard Flow Logs log group.
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"

      values = [
        "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/cloudguard/vpc-flow-logs"
      ]
    }

    # Require requests to pass through CloudWatch Logs.
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "logs.${var.aws_region}.amazonaws.com"
      ]
    }
  }
}

# Dedicated customer-managed key for CloudGuard Flow Logs.
resource "aws_kms_key" "cloudguard_flow_logs" {
  description             = "Encrypt CloudGuard VPC Flow Logs"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = data.aws_iam_policy_document.cloudguard_kms.json

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
    Purpose     = "VPC Flow Logs encryption"
  }
}
