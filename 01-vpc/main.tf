terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Configure Remote Backend (with State Locking)
  backend "s3" {
    bucket         = "riad-tfstate-bucket-2026"
    key            = "projet-dx/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "scalingBackendTable"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-3"
}

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main_vpc"
  }
}

resource "aws_subnet" "main_public_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "main_public_subnet"
  }
}

resource "aws_subnet" "main_private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-3a"
  tags = {
    Name = "main_private_subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "internet_gw"
  }
}

# Table de Routage R1 (public)
resource "aws_route_table" "R1" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    # Si joindre n'importe quelle @ sur internet
    cidr_block = "0.0.0.0/0"
    # Alors passer par la gateway internet
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "R1"
  }
}

# Liaison table de routage R1 --> Subnet Public
resource "aws_route_table_association" "A1" {
  subnet_id      = aws_subnet.main_public_subnet.id
  route_table_id = aws_route_table.R1.id
}

# Création d'une @IP publique statique pour le NAT (exigence AWS)
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# NAT gateway pour permettre l'accès du subnet privé à Internet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.main_public_subnet.id
  # Attendre la construction de la gateway internet avant de créer le NAT
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "nat_gw"
  }
}

# Table de Routage R2 (private)
resource "aws_route_table" "R2" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "R2"
  }
}

# Liaison table de routage R2 --> Subnet Private
resource "aws_route_table_association" "A2" {
  subnet_id      = aws_subnet.main_private_subnet.id
  route_table_id = aws_route_table.R2.id
}

# Security Groups 

## Vigile du Frontend (Public) 

resource "aws_security_group" "frontend_sg" {
  name        = "frontend_sg"
  description = "Autorise le trafic HTTP entrant depuis Internet"
  vpc_id      = aws_vpc.main_vpc.id

  # Règle entrante (Ingress) : Autorise port 80 depuis n'importe où
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Règle sortante (Egress) : Autorise le serveur à parler à tout le monde (nécessaire pour télécharger des paquets ou répondre aux clients)
  egress {
    from_port = 0
    to_port   = 0
    # tous les protocoles
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "frontend_sg"
  }
}

## Vigile du Backend (Private)

resource "aws_security_group" "backend_sg" {
  name        = "backend_sg"
  description = "Autorise le trafic 8000 entrant depuis le frontend"
  vpc_id      = aws_vpc.main_vpc.id

  # Règle entrante (Ingress) : autorise le port 8000 depuis le frontend
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  # Règle sortante (Egress) : autorise le serveur à parler à tout le monde

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend_sg"
  }
}
