resource "aws_vpc" "cloudguard" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "cloudguard-vpc"
    Environment = "lab"
    Project     = "CloudGuard"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.cloudguard.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name        = "cloudguard-public-subnet"
    Environment = "lab"
    Project     = "CloudGuard"
    Tier        = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.cloudguard.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name        = "cloudguard-private-subnet"
    Environment = "lab"
    Project     = "CloudGuard"
    Tier        = "private"
  }
}

resource "aws_internet_gateway" "cloudguard" {
  vpc_id = aws_vpc.cloudguard.id

  tags = {
    Name        = "cloudguard-igw"
    Environment = "lab"
    Project     = "CloudGuard"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cloudguard.id

  tags = {
    Name        = "cloudguard-public-rt"
    Environment = "lab"
    Project     = "CloudGuard"
    Tier        = "public"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cloudguard.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "cloudguard_test" {
  name        = "cloudguard-test-sg"
  description = "Security group for the CloudGuard test instance"
  vpc_id      = aws_vpc.cloudguard.id

  egress {
    description = "Allow outbound IPv4 traffic for the lab"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "cloudguard-test-sg"
    Environment = "lab"
    Project     = "CloudGuard"
  }
}
