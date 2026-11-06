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

resource "aws_ecs_task_definition" "cloudguard" {
  family                   = "cloudguard-api"
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"

  }
  network_mode = "awsvpc"
  cpu          = 256
  memory       = 512

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  lifecycle {
    ignore_changes = [
      container_definitions,
      volume
    ]
  }

  container_definitions = jsonencode([
    {
      name      = "cloudguard-api"
      image     = "${aws_ecr_repository.cloudguard.repository_url}:v2.0.0"
      essential = true

      user                   = "101"
      readonlyRootFilesystem = true
      privileged             = false

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      linuxParameters = {
        capabilities = {
          drop = ["ALL"]
        }
      }

      mountPoints = [
        {
          sourceVolume  = "nginx-tmp"
          containerPath = "/tmp"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = "/ecs/cloudguard-api"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  volume {
    name = "nginx-tmp"
  }

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
  }

  depends_on = [
    aws_cloudwatch_log_group.cloudguard_ecs
  ]
}
