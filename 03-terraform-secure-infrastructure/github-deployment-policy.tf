# GitHub Actions deployment permissions

data "aws_iam_policy_document" "github_deployment" {

  # ECR authentication
  statement {
    sid       = "ECRAuthentication"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Push images only to the CloudGuard repository
  statement {
    sid    = "ECRImagePublishing"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]

    resources = [
      aws_ecr_repository.cloudguard.arn
    ]
  }

  # Register CloudGuard task definition revisions
  statement {
    sid     = "RegisterCloudGuardTaskDefinition"
    effect  = "Allow"
    actions = ["ecs:RegisterTaskDefinition"]

    resources = [
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/cloudguard-api:*"
    ]
  }

  # Describe task definitions
  statement {
    sid       = "DescribeTaskDefinitions"
    effect    = "Allow"
    actions   = ["ecs:DescribeTaskDefinition"]
    resources = ["*"]
  }

  # Update and inspect only the CloudGuard service
  statement {
    sid    = "CloudGuardServiceDeployment"
    effect = "Allow"

    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices"
    ]

    resources = [
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/cloudguard-cluster/cloudguard-api-service"
    ]
  }

  # Inspect the CloudGuard cluster
  statement {
    sid     = "CloudGuardClusterInspection"
    effect  = "Allow"
    actions = ["ecs:DescribeClusters"]

    resources = [
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/cloudguard-cluster"
    ]
  }

  # Pass only the designated ECS task roles
  statement {
    sid     = "PassOnlyCloudGuardECSRoles"
    effect  = "Allow"
    actions = ["iam:PassRole"]

    resources = [
      aws_iam_role.ecs_task_execution.arn,
      aws_iam_role.ecs_task.arn
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Attach deployment permissions to the GitHub role
resource "aws_iam_role_policy" "github_deployment" {
  name   = "CloudGuardGitHubDeploymentPolicy"
  role   = aws_iam_role.github_deployment.id
  policy = data.aws_iam_policy_document.github_deployment.json
}
