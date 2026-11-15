packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "backend-ami" {
  region = "eu-west-3"
  instance_type = "t3.micro"
  # username to connect to ssh with
  ssh_username = "ubuntu" 
  # {{timestamp}} useful for unique keys like ami_name, it return a string
  ami_name = "iac-backend-golden-image-{{timestamp}}"

  # Filtres de recherche de l'ami source
  source_ami_filter {
    filters = {
      name = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      # disque dur principal (root) de type EBS (Elastic Block Store) pour AWS
      root-device-type = "ebs"
      # HVM (hardware Virtual Machine) type de virtualisaiton moderne AWS
      virtualization-type = "hvm"
    }
    # Rechercher que les images les plus récentes 
    most_recent = true
    # Sécurité : pour avoir l'image depuis le compte officiel de Canonical (créateur d'Ubuntu)
    owners = ["099720109477"]
  }
}

build {
  # Prendre le moule temporaire défini en haut
  sources =["source.amazon-ebs.backend-ami"]

  # Livrer les fichiers locaux de manière sécurisée dans le disque dur de la machine temporaire AWS
  provisioner "file" {
    source = "../02-app/backend/"
    # Dossier uploader 
    destination = "/home/ubuntu/backend_app" 
  }

  # Runner des commandes Linux sur la machine AWS
  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io",
      "cd /home/ubuntu/backend_app",
      "sudo docker build -t iac-backend ."
    ]
  }
}
