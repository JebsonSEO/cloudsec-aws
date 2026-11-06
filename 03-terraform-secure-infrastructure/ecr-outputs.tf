output "cloudguard_ecr_repository_url" {
  description = "CloudGuard ECR repository URL"
  value       = aws_ecr_repository.cloudguard.repository_url
}

output "cloudguard_ecr_kms_key_arn" {
  description = "CloudGuard ECR encryption key ARN"
  value       = aws_kms_key.cloudguard_ecr.arn
}
