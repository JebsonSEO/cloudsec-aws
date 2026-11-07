data "aws_iam_policy_document" "cloudguard_waf_logs_kms" {
  #checkov:skip=CKV_AWS_109: Account-root principal enables IAM-based administration of this dedicated KMS key.
  #checkov:skip=CKV_AWS_356: Resource "*" is the conventional scope for a KMS key policy attached to a specific key.
  #checkov:skip=CKV_AWS_111: Explicit KMS administrative permissions are restricted to the AWS account root principal.

  # Retain account-level IAM administration of the KMS key.
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

  # Allow CloudWatch Logs to encrypt and decrypt WAF log data.
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
      "kms:GenerateDataKey*"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"

      values = [
        "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:aws-waf-logs-cloudguard"
      ]
    }
  }

  # Allow CloudWatch Logs to describe the KMS key.
  statement {
    sid    = "AllowCloudWatchLogsDescribeKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }

    actions = [
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }

  # Allow the restricted Terraform deployment user to create the alias.
  statement {
    sid    = "AllowTerraformDeployerToCreateCloudGuardWAFLogsAlias"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/terraform-deployer"
      ]
    }

    actions = [
      "kms:CreateAlias",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }
}

resource "aws_kms_key" "cloudguard_waf_logs" {
  description             = "Encrypt CloudGuard AWS WAF logs"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = data.aws_iam_policy_document.cloudguard_waf_logs_kms.json

  tags = {
    Name        = "cloudguard-waf-logs-key"
    Project     = "CloudGuard"
    Environment = "lab"
    Purpose     = "WAF log encryption"
  }
}

resource "aws_kms_alias" "cloudguard_waf_logs" {
  name          = "alias/cloudguard-waf-logs"
  target_key_id = aws_kms_key.cloudguard_waf_logs.key_id
}
