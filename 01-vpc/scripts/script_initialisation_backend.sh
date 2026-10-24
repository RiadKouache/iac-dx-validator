#!/bin/bash

# ==============================================================================
# SCRIPT D'INITIALISATION (USER DATA) - SERVEUR BACKEND
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
# Utilisation d'un chemin absolu (/app) pour éviter le piège du dossier /root

mkdir -p /app
cd /app 

----------------------------------------------------------------------------
# 3. GÉNÉRATION DES FICHIERS APPLICATIFS (Technique du Heredoc)
# ------------------------------------------------------------------------------

# -> Création du Dockerfile 

cat << 'EOF' > Dockerfile
# Utilisation d'une image Python officielle, version allégée (slim)
FROM python:3.11-slim
# Définition du répertoire de travail dans le conteneur
WORKDIR /app
# Copie des dépendances et installation (optimisation du cache Docker)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# Copie du reste du code source (dont main.py)
COPY . .
# Exposition du port (doit correspondre à l'Ingress de ton Security Group AWS)
EXPOSE 8000
# Commande de démarrage du serveur
CMD [ "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# -> Création du code Python (main.py)
cat << 'EOF' > main.py 
from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Iac DX Validator - Backend API")

# Autorise le Frontend à communiquer avec cette API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # En prod, on mettrait l'IP exacte du Frontend
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Instrumentator().instrument(app).expose(app)

@app.get("/")
def read_root():
    return {
        "message": "Hello depuis le Subnet Privé !",
        "status": "success"
    }

@app.get("/health")
def healt_check():
    return {"status": "healthy"}

EOF

# -> Création de la liste des dépendances (requirements.txt)
cat << 'EOF' > requirements.txt
fastapi==0.103.1
uvicorn==0.23.2
prometheus-fastapi-instrumentator==6.1.0

EOF

# ------------------------------------------------------------------------------
# 4. DELIVERY : CONSTRUCTION ET DÉPLOIEMENT
# ------------------------------------------------------------------------------
# Le code est présent, on emballe l'application

docker build -t iac-backend . 
# L'option '--restart unless-stopped' est la garantie de résilience SRE
docker run -d -p 8000:8000 --name mon-backend --restart unless-stopped iac-backend



