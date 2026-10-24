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

