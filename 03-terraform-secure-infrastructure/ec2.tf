# Retrieve the current recommended Amazon Linux 2023 AMI.
data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# CloudGuard lab instance, managed through Systems Manager.
resource "aws_instance" "cloudguard_lab" {
  ami           = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.cloudguard_test.id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.cloudguard_ec2.name

  # Require IMDSv2 for instance metadata access.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Encrypt the root volume at rest.
  root_block_device {
    encrypted             = true
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "cloudguard-ssm-lab"
    Environment = "lab"
    Project     = "CloudGuard"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm_core
  ]
}
