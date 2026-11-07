resource "aws_cloudwatch_log_group" "cloudguard_ecs" {
  name              = "/ecs/cloudguard-api"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudguard_ecs_logs.arn

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
    Purpose     = "Encrypted ECS application logs"
  }
}
