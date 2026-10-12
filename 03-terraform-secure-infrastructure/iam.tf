# Allows EC2 instances to assume this role.
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM role assumed by the CloudGuard EC2 instance.
resource "aws_iam_role" "cloudguard_ec2" {
  name               = "cloudguard-ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

# Grants the EC2 instance the permissions required by Systems Manager.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.cloudguard_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Makes the IAM role available to EC2.
resource "aws_iam_instance_profile" "cloudguard_ec2" {
  name = "cloudguard-ec2-ssm-profile"
  role = aws_iam_role.cloudguard_ec2.name
}
