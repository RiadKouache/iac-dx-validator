#!/bin/bash

# ==============================================================================
# SCRIPT D'INITIALISATION (USER DATA) - SERVEUR FRONTEND
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
# 3. GÉNÉRATION DES FICHIERS APPLICATIFS (Technique du Heredoc)
# ------------------------------------------------------------------------------

# -> Création du Dockerfile

cat << 'EOF' > Dockerfile 
# On utilise un serveur web Nginx très léger
FROM nginx:alpine
# On copie notre fichier web dans le dossier public de Nginx
COPY index.html /usr/share/nginx/html/index.html
# On copie notre ficher configuration Nginx dans le dossier de conf Nginx
COPY default.conf /etc/nginx/conf.d/default.conf
# Nginx écoute par défaut sur le port 80 (standard HTTP)
EXPOSE 80
# Démarrage du serveur en tâche de fond
CMD ["nginx", "-g", "daemon off;"]
EOF

# -> Création du default.conf
cat << 'EOF' > default.conf
server {
    listen 80;
    # 1. Servir le Frontend (Vue.js)
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
    # 2. Le Reverse Proxy vers le Backend
    location /api/ {
        # L'IP sera injectée dynamiquement par Terraform plus tard !
        proxy_pass http://${backend_private_ip}:8000/;
    }
}
EOF

# -> Création du index.html (Vue.js)

cat << 'EOF' > index.html
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>IaC DX Validator</title>
    <!-- Importation de Vue 3 via CDN pour un projet léger -->
    <script src="https://unpkg.com/vue@3/dist/vue.global.js"></script>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f4f9; text-align: center; padding: 50px; }
        .card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); display: inline-block; }
        button { background-color: #4CAF50; color: white; border: none; padding: 10px 20px; cursor: pointer; border-radius: 4px; margin-top: 15px;}
    </style>
</head>
<body>
    <div id="app" class="card">
        <h1>🌐 {{ titre }}</h1>
        <p><strong>Statut :</strong> <span style="color: green;">Connecté au Frontend</span></p>
        <hr>
        <h3>Réponse du Backend :</h3>
        <p style="font-size: 1.2em; color: #333;">{{ messageBackend }}</p>
        <button @click="fetchData">Tester la connexion Backend</button>
    </div>

    <script>
        const { createApp, ref, onMounted } = Vue;

        createApp({
            setup() {
                const titre = ref('Dashboard SRE - Frontend');
                const messageBackend = ref('En attente de connexion...');

                const fetchData = async () => {
                    try {
                        // On interroge ton API locale
                        const reponse = await fetch('/api/');
                        const data = await reponse.json();
                        messageBackend.value = data.message;
                    } catch (error) {
                        messageBackend.value = "Erreur : Impossible de joindre l'API Backend.";
                    }
                };

                // Lance la requête dès que la page s'affiche
                onMounted(fetchData);

                return { titre, messageBackend, fetchData }
            }
        }).mount('#app')
    </script>
</body>
</html>
EOF


# ------------------------------------------------------------------------------
# 4. DELIVERY : CONSTRUCTION ET DÉPLOIEMENT
# ------------------------------------------------------------------------------
# Le code est présent, on emballe l'application

docker build -t iac-frontend .
docker run -d -p 80:80 --name mon-frontend --restart unless-stopped iac-frontend

