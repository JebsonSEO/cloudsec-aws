variable "aws_region" {
  description = "AWS region where CloudGuard infrastructure will be deployed"
  type        = string
  default     = "eu-north-1"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the CloudGuard VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "IPv4 CIDR block for the public subnet"
  type        = string
  default     = "10.20.1.0/24"
}

variable "private_subnet_cidr" {
  description = "IPv4 CIDR block for the private subnet"
  type        = string
  default     = "10.20.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the initial CloudGuard subnets"
  type        = string
  default     = "eu-north-1a"
}
