resource "aws_wafv2_web_acl" "cloudguard" {
  name        = "cloudguard-web-acl"
  scope       = "REGIONAL"
  description = "AWS Managed Common Rule Set and Known Bad Inputs protection for CloudGuard ALB"

  default_action {
    allow {}
  }

  # AWS Managed Common Rule Set
  rule {
    name     = "AWSManagedCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CloudGuardCommonRules"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Known Bad Inputs Rule Set
  rule {
    name     = "AWSManagedKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CloudGuardKnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CloudGuardWebACL"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "anonymous-ip-list"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Name        = "cloudguard-web-acl"
    Environment = "lab"
    Project     = "CloudGuard"
  }
}

# Associate WAF with the Application Load Balancer
resource "aws_wafv2_web_acl_association" "cloudguard" {
  resource_arn = aws_lb.cloudguard.arn
  web_acl_arn  = aws_wafv2_web_acl.cloudguard.arn
}

# WAF log destination
resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-cloudguard"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudguard_waf_logs.arn

  tags = {
    Name        = "cloudguard-waf-logs"
    Project     = "CloudGuard"
    Environment = "lab"
  }
}

# Permission for AWS WAF log delivery
resource "aws_cloudwatch_log_resource_policy" "waf" {
  policy_name = "cloudguard-waf-logging-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AWSWAFLoggingPermissions"
        Effect = "Allow"

        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.waf.arn}:*"

        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }

          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
}

# Enable WAF logging
resource "aws_wafv2_web_acl_logging_configuration" "cloudguard" {
  resource_arn            = aws_wafv2_web_acl.cloudguard.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]

  depends_on = [
    aws_cloudwatch_log_resource_policy.waf
  ]
}
