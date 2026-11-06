resource "aws_ecs_service" "cloudguard" {
  name            = "cloudguard-api-service"
  cluster         = aws_ecs_cluster.cloudguard.id
  task_definition = aws_ecs_task_definition.cloudguard.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  platform_version = "LATEST"

  network_configuration {
    subnets = [
      aws_subnet.private.id,
      aws_subnet.private_b.id
    ]

    security_groups = [
      aws_security_group.ecs_tasks.id
    ]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.cloudguard.arn
    container_name   = "cloudguard-api"
    container_port   = 8080
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Project     = "CloudGuard"
    Environment = "lab"
  }

  depends_on = [
    aws_vpc_endpoint.ecs_interface,
    aws_vpc_endpoint.s3,
    aws_cloudwatch_log_group.cloudguard_ecs,
    aws_lb_listener.cloudguard_http
  ]
}
