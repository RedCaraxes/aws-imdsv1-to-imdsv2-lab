resource "aws_iam_role" "lab" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = var.iam_role_name
    Purpose = "IMDS lab - intentionally no resource permissions"
  }
}

resource "aws_iam_instance_profile" "lab" {
  name = "${var.name_prefix}-instance-profile"
  role = aws_iam_role.lab.name
}
