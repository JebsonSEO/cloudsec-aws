# Reviewed Checkov exceptions:
# checkov:skip=CKV_AWS_109:Account-root principal enables IAM-based administration of this dedicated KMS key; administrative actions are explicitly listed.
# checkov:skip=CKV_AWS_356:Resource "*" is the conventional scope for a KMS key policy attached to a specific key.
# checkov:skip=CKV_AWS_111:Explicit KMS administrative permissions are restricted to the AWS account root principal.

data "aws_iam_policy_document" "cloudguard_ecs_logs_kms" {

  # Reviewed Checkov exceptions:
  # checkov:skip=CKV_AWS_109:Account-root principal enables IAM-based administration of this dedicated KMS key.
  # checkov:skip=CKV_AWS_356:Resource "*" is the conventional scope for a KMS key policy attached to a specific key.
  # checkov:skip=CKV_AWS_111:Explicit KMS administrative permissions are restricted to the AWS account root principal.
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
      "kms:CreateAlias",
      "kms:GetKeyPolicy",
      "kms:PutKeyPolicy",
      "kms:EnableKeyRotation",
      "kms:GetKeyRotationStatus",
      "kms:ListResourceTags",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
      "kms:RetireGrant",
      "kms:DisableKey",
      "kms:EnableKey",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]

    resources = ["*"]
  }

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

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"

      values = [
        "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/cloudguard-api"
      ]
    }
  }
}

resource "aws_kms_key" "cloudguard_ecs_logs" {
  description             = "Encrypt CloudGuard ECS application logs"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = data.aws_iam_policy_document.cloudguard_ecs_logs_kms.json

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
    Purpose     = "ECS application log encryption"
  }
}

resource "aws_kms_alias" "cloudguard_ecs_logs" {
  name          = "alias/cloudguard-ecs-logs"
  target_key_id = aws_kms_key.cloudguard_ecs_logs.key_id
}
