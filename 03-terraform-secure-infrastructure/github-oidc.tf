# GitHub Actions OIDC Identity Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
    Purpose     = "GitHub Actions OIDC authentication"
  }
}


# GitHub Actions Deployment Role Trust Policy
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:JebsonSEO/cloudsec-aws:ref:refs/heads/main"
      ]
    }
  }
}


# Dedicated GitHub Actions Deployment Role
resource "aws_iam_role" "github_deployment" {
  name = "CloudGuardGitHubDeploymentRole"

  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  description = "Restricted deployment role for CloudGuard GitHub Actions"

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
    Purpose     = "Automated secure AWS deployment"
  }
}
