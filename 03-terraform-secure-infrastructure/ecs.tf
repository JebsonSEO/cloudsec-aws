# ============================================================
# CLOUDGUARD ECS CLUSTER
# ============================================================

resource "aws_ecs_cluster" "cloudguard" {
  name = "cloudguard-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
  }
}


# ============================================================
# CLOUDGUARD ECS TASK DEFINITION
# ============================================================

resource "aws_ecs_task_definition" "cloudguard" {
  family                   = "cloudguard-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [container_definitions]
  }

  container_definitions = replace(
    replace(
      file("${path.module}/cloudguard-containers.json"),
      "__IMAGE_URI__",
      "${aws_ecr_repository.cloudguard.repository_url}:v2.0.0"
    ),
    "__AWS_REGION__",
    var.aws_region
  )

  # Shared writable temporary volume.
  volume {
    name = "nginx-tmp"
  }

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
  }
}
