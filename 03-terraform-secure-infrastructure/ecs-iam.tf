# ECS Task Execution Role
data "aws_iam_policy_document" "ecs_task_execution_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "cloudguard-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_trust.json

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# ECS Application Task Role
data "aws_iam_policy_document" "ecs_task_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task" {
  name               = "cloudguard-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust.json

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
  }
}
