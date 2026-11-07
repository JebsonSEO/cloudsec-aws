resource "aws_s3_bucket" "alb_logs" {
 #checkov:skip=CKV_AWS_18:Dedicated server access logging bucket is outside this lab scope.
 #checkov:skip=CKV_AWS_145:ALB delivery bucket uses SSE-S3 encryption.
 #checkov:skip=CKV2_AWS_62:No event-processing workflow requires S3 notifications.
 #checkov:skip=CKV_AWS_144:Cross-region replication is unnecessary for this single-region lab.

  bucket        = "cloudguard-alb-logs-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  force_destroy = false

  tags = {
    Name        = "cloudguard-alb-logs"
    Environment = "lab"
    Project     = "CloudGuard"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  #checkov:skip=CKV_AWS_300: Incomplete multipart uploads are already configured for automatic abortion after 7 days; Checkov 3.3.28 does not recognize the nested lifecycle block.

  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "expire-alb-logs"
    status = "Enabled"

    filter {
      prefix = "cloudguard/"
    }

    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  depends_on = [
    aws_s3_bucket_public_access_block.alb_logs
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBLogDelivery"
        Effect = "Allow"

        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }

        Action = "s3:PutObject"

        Resource = "${aws_s3_bucket.alb_logs.arn}/cloudguard/AWSLogs/${data.aws_caller_identity.current.account_id}/*"

        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:loadbalancer/*"
          }

          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}
