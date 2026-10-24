resource "aws_security_group" "obs_sg" {
  name        = "obs_sg"
  description = "Autoriser interrogation vers backend et acces depuis exterieur"
  vpc_id      = aws_vpc.main_vpc.id

  # Règle Grafana (Ingress) : Autorise uniquement IP publique perso (port 3000) pour admin
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["78.241.205.140/32"]
  }
  # Règle Prometheus (Ingress) : Autorise IP publique perso (port 9090) pour débuggage
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["78.241.205.140/32"]
  }

  # Règle sortante (Egress) : Autoriser l'ouverture vers Internet pour MAJ
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_instance" "obs_server" {

  ami = "ami-05b5a865c3579bbc4"

  instance_type = "t3.micro"

  subnet_id = aws_subnet.main_public_subnet.id

  vpc_security_group_ids = [aws_security_group.obs_sg.id]

  # Assigner une IP publique à l'instance pour y accèder depuis Internet	
  associate_public_ip_address = true

  # Script d'initialisation du serveur d'observabilité 
  user_data = templatefile("${path.module}/scripts/script_initialisation_obs.sh", { backend_private_ip = aws_instance.backend_server.private_ip })
}
