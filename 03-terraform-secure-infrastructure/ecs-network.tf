# Security group for CloudGuard ECS Fargate tasks.
resource "aws_security_group" "ecs_tasks" {
  name        = "cloudguard-ecs-tasks-sg"
  description = "Security group for CloudGuard ECS Fargate tasks"
  vpc_id      = aws_vpc.cloudguard.id

  tags = {
    Name        = "cloudguard-ecs-tasks-sg"
    Environment = "lab"
    Project     = "CloudGuard"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.cloudguard.id

  tags = {
    Name        = "cloudguard-private-rt"
    Environment = "lab"
    Project     = "CloudGuard"
    Tier        = "private"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# Security group for private AWS interface endpoints.
resource "aws_security_group" "ecs_vpce" {
  name        = "cloudguard-ecs-vpce-sg"
  description = "HTTPS access to CloudGuard ECS VPC endpoints"
  vpc_id      = aws_vpc.cloudguard.id

  tags = {
    Name        = "cloudguard-ecs-vpce-sg"
    Environment = "lab"
    Project     = "CloudGuard"
  }
}

# Permit HTTPS from ECS tasks to interface endpoints.
resource "aws_vpc_security_group_ingress_rule" "ecs_to_vpce" {
  security_group_id            = aws_security_group.ecs_vpce.id
  referenced_security_group_id = aws_security_group.ecs_tasks.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "HTTPS from CloudGuard ECS tasks"
}

# Restrict ECS outbound HTTPS to the endpoint security group.
resource "aws_vpc_security_group_egress_rule" "ecs_to_vpce" {
  security_group_id            = aws_security_group.ecs_tasks.id
  referenced_security_group_id = aws_security_group.ecs_vpce.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "HTTPS to approved AWS interface endpoints"
}

resource "aws_vpc_endpoint" "ecs_interface" {
  for_each = toset(["ecr.api", "ecr.dkr", "logs"])

  vpc_id            = aws_vpc.cloudguard.id
  service_name      = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type = "Interface"
  subnet_ids = [
    aws_subnet.private.id,
    aws_subnet.private_b.id
  ]
  security_group_ids  = [aws_security_group.ecs_vpce.id]
  private_dns_enabled = true

  tags = {
    Name        = "cloudguard-${replace(each.value, ".", "-")}-endpoint"
    Environment = "lab"
    Project     = "CloudGuard"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.cloudguard.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name        = "cloudguard-s3-endpoint"
    Environment = "lab"
    Project     = "CloudGuard"
  }
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_s3" {
  security_group_id = aws_security_group.ecs_tasks.id
  prefix_list_id    = data.aws_prefix_list.s3.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "HTTPS to S3 for ECR image layers"
}
