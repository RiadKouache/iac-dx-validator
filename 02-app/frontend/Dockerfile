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
