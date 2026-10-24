output "dashboard_url" {
  description = "L'adresse IP publique pour accéder au site web Frontend"
  # Chercher la ressource -> nom -> attribut IP publique
  value = "http://${aws_instance.frontend_server.public_ip}"
}

output "public_ip_obs_server" {
  description = "Adresse IP publique du serveur d'oberservabilité Prometheus/Grafana"
  value       = aws_instance.obs_server.public_ip
}

output "private_ip_backend" {
  description = "L'adresse IP privée du serveur API"
  # Chercehr la ressource -> nom -> attribut IP privé
  value = aws_instance.backend_server.private_ip
}
