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
  }

  container_definitions = jsonencode([

    # --------------------------------------------------------
    # INITIALIZATION CONTAINER
    # Prepares the shared temporary volume for NGINX.
    # --------------------------------------------------------

    {
      name      = "cloudguard-init-tmp"
      image     = "${aws_ecr_repository.cloudguard.repository_url}:v2.0.0"
      essential = false

      user = "0"

      entryPoint = [
        "/bin/sh",
        "-c"
      ]

      command = [
        "chown 101:101 /tmp && chmod 700 /tmp"
      ]

      readonlyRootFilesystem = true
      privileged             = false

      mountPoints = [
        {
          sourceVolume  = "nginx-tmp"
          containerPath = "/tmp"
          readOnly      = false
        }
      ]
    },

    # --------------------------------------------------------
    # MAIN NGINX APPLICATION CONTAINER
    # --------------------------------------------------------

    {
      name      = "cloudguard-api"
      image     = "${aws_ecr_repository.cloudguard.repository_url}:v2.0.0"
      essential = true

      user                   = "101"
      privileged             = false
      readonlyRootFilesystem = true

      dependsOn = [
        {
          containerName = "cloudguard-init-tmp"
          condition     = "SUCCESS"
        }
      ]

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
          awslogs-group         = "/ecs/cloudguard-api"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "false"
        }
      }
    }
  ])

  # Shared writable temporary volume.
  volume {
    name = "nginx-tmp"
  }

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
  }
}
