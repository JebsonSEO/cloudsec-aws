resource "aws_ecr_repository" "cloudguard" {
  name                 = "cloudguard-app"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.cloudguard_ecr.arn
  }

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
    Purpose     = "Secure container image storage"
  }
}

resource "aws_ecr_lifecycle_policy" "cloudguard" {
  repository = aws_ecr_repository.cloudguard.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 14 days"

        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }

        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Retain the latest 10 version-tagged images"

        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}
