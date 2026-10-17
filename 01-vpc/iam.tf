# Le Rôle IAM pour le Backend
resource "aws_iam_role" "backend_role" {
  name = "backend_role"

  # Trust Policy : Autorise le service EC2 à endosser ce rôle
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "backend_role"
  }
}

resource "aws_iam_role_policy_attachment" "backend_s3_read" {
	role = aws_iam_role.backend_role.name
	policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "backend_profile" {
	name = "backend_profile"
	role = aws_iam_role.backend_role.name
}
