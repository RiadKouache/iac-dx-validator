output "dashboard_url" {
  description = "L'adresse IP publique pour accéder au site web Frontend"
  # Chercher la ressource -> nom -> attribut IP publique
  value = "http://${aws_instance.frontend_server.public_ip}"
}

output "private_ip_backend" {
  description = "L'adresse IP privée du serveur API"
  # Chercehr la ressource -> nom -> attribut IP privé
  value = aws_instance.backend_server.private_ip
}
