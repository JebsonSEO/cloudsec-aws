# Security group for Systems Manager interface VPC endpoints.
resource "aws_security_group" "ssm_vpce" {
  name        = "cloudguard-ssm-vpce-sg"
  description = "Security group for CloudGuard SSM VPC endpoints"
  vpc_id      = aws_vpc.cloudguard.id

  egress = []

  tags = {
    Name        = "cloudguard-ssm-vpce-sg"
    Environment = "lab"
    Project     = "CloudGuard"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssm_from_ec2" {
  security_group_id            = aws_security_group.ssm_vpce.id
  referenced_security_group_id = aws_security_group.cloudguard_test.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "HTTPS from CloudGuard EC2"
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = toset(["ssm", "ssmmessages"])

  vpc_id              = aws_vpc.cloudguard.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.ssm_vpce.id]
  private_dns_enabled = true

  tags = {
    Name        = "cloudguard-${each.value}-endpoint"
    Environment = "lab"
    Project     = "CloudGuard"
  }
}

# Allow EC2 to send HTTPS traffic only to the SSM endpoint security group.
resource "aws_vpc_security_group_egress_rule" "ec2_to_ssm" {
  security_group_id            = aws_security_group.cloudguard_test.id
  referenced_security_group_id = aws_security_group.ssm_vpce.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "HTTPS only to Systems Manager VPC endpoints"
}
