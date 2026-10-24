#!/bin/bash

# ==============================================================================
# SCRIPT D'INITIALISATION (USER DATA) - SERVEUR OBSERVABILITY
# Exécuté une seule fois par l'utilisateur 'root' au premier démarrage de l'EC2.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. INSTALLATION DU MOTEUR
# ------------------------------------------------------------------------------
# Mise à jour des paquets et installation de Docker sur le Linux vierge

apt-get update -y
apt-get install -y docker.io

# ------------------------------------------------------------------------------
# 2. PRÉPARATION DE L'ESPACE DE TRAVAIL
# ------------------------------------------------------------------------------

mkdir -p /app
cd /app


#----------------------------------------------------------------------------
# 3. GÉNÉRATION DU FICHIER CONF PROMETHEUS (Technique du Heredoc)
# ------------------------------------------------------------------------------

cat <<'EOF'> prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'iac-backend'
    static_configs:
      # C'est ici que la magie doit opérer !
      - targets: ['${backend_private_ip}:8000']
EOF


# ------------------------------------------------------------------------------
# 4. DELIVERY : CONSTRUCTION ET DÉPLOIEMENT
# ------------------------------------------------------------------------------
# On utilise directement les images pré_construites officielles Prometheus Grafana 

# Prometheus : On attache au conteneur notre fichier de conf Prometheus via un volume Docker
docker run -d -p 9090:9090 --name prometheus --restart unless-stopped -v /app/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
# Grafana
docker run -d -p 3000:3000 --name grafana --restart unless-stopped grafana/grafana

