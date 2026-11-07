# Security group for the public Application Load Balancer.
resource "aws_security_group" "alb" {
  name        = "cloudguard-alb-sg"
  description = "Security group for CloudGuard public ALB"
  vpc_id      = aws_vpc.cloudguard.id

  tags = {
    Name        = "cloudguard-alb-sg"
    Project     = "CloudGuard"
    Environment = "lab"
  }
}

# Allow public HTTP traffic to the ALB.
# Temporary lab configuration pending domain and HTTPS certificate.
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  #checkov:skip=CKV_AWS_260:Public HTTP is temporarily required for this certificate-free portfolio lab; production deployment will restrict access to HTTPS.

  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  description = "Temporary HTTP access for CloudGuard lab"
}

# Allow ALB outbound traffic only to ECS application port.
resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.ecs_tasks.id

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080

  description = "Forward application traffic to CloudGuard ECS tasks"
}

# Allow application traffic to ECS only from the ALB.
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs_tasks.id
  referenced_security_group_id = aws_security_group.alb.id

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080

  description = "Allow application traffic exclusively from CloudGuard ALB"
}

# CloudGuard Application Load Balancer.
resource "aws_lb" "cloudguard" {
  #checkov:skip=CKV2_AWS_20:HTTP-to-HTTPS redirection requires an HTTPS listener; this lab currently has no domain or ACM certificate.

  name                       = "cloudguard-public-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  drop_invalid_header_fields = true

  subnets = [
    aws_subnet.public.id,
    aws_subnet.public_b.id
  ]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "cloudguard"
    enabled = true
  }

  tags = {
    Name        = "cloudguard-public-alb"
    Project     = "CloudGuard"
    Environment = "lab"
  }

  depends_on = [
    aws_s3_bucket_policy.alb_logs
  ]
}

# Target group for private ECS Fargate tasks.
resource "aws_lb_target_group" "cloudguard" {
  #checkov:skip=CKV_AWS_378:HTTP is used between the ALB and private ECS tasks within the VPC; backend TLS is outside this lab's current architecture.

  name        = "cloudguard-api-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.cloudguard.id

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "cloudguard-api-tg"
    Project     = "CloudGuard"
    Environment = "lab"
  }
}

# HTTP listener for temporary lab access.
resource "aws_lb_listener" "cloudguard_http" {
  #checkov:skip=CKV_AWS_2:HTTPS listener requires a domain and ACM certificate, neither of which is configured for this lab.
  #checkov:skip=CKV_AWS_103:TLS security policy applies to HTTPS listeners; HTTPS configuration is deferred to production.

  load_balancer_arn = aws_lb.cloudguard.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cloudguard.arn
  }
}
