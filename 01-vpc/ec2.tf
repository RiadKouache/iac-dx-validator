# Fichier: ec2.tf

# Serveur Backend (Privé)
resource "aws_instance" "backend_server" {
  # AMI d'un OS Linux standard sur la région eu-west-3 (Paris)
  ami           = "ami-05b5a865c3579bbc4"
  instance_type = "t3.micro"

  # On le place dans le subnet privé
  subnet_id = aws_subnet.main_private_subnet.id

  # On lui attache son vigile
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  # On lui donne son uniforme IAM (le porte-badge)
  iam_instance_profile = aws_iam_instance_profile.backend_profile.name

  tags = {
    Name = "backend_server"
  }
}

resource "aws_instance" "frontend_server" {
  ami           = "ami-05b5a865c3579bbc4"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.main_public_subnet.id

  vpc_security_group_ids = [aws_security_group.frontend_sg.id]

  tags = {
    Name = "frontend_server"
  }
}
