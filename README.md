# 🚀 IaC DX Validator : Architecture DevSecOps 3-Tiers sur AWS

Ce projet démontre le déploiement entièrement automatisé et sécurisé d'une architecture web 3-Tiers (Frontend, Backend, Observabilité) sur Amazon Web Services (AWS) en utilisant l'Infrastructure as Code (Terraform) et les principes du DevOps (Docker, CI/CD).

## 🎯 Objectifs du Projet

- **Provisionnement Automatisé :** Création de l'infrastructure réseau et calcul de A à Z (VPC, Subnets, EC2, NAT Gateway) via Terraform.
- **Sécurité (DevSecOps) :** Isolation du Backend en réseau privé, whitelisting strict, et gestion du Remote State sécurisé (S3 + DynamoDB).
- **Livraison Continue (Delivery) :** Configuration des serveurs au démarrage (cloud-init/user_data) et conteneurisation des applications (Docker).
- **Observabilité SRE :** Mise en place d'une stack de monitoring (Prometheus & Grafana) pour suivre la santé de l'API.

---

## 🏗️ Architecture Réseau et Sécurité

Le projet repose sur la séparation stricte des responsabilités (Separation of Concerns) et le principe du moindre privilège.

![Instances EC2 AWS](images/instances.png)
*(Capture 1 : Les 3 instances provisionnées : Frontend, Backend, Observabilité)*

### 1. Le Réseau (VPC & Routage)
- **Subnet Public :** Héberge le `frontend_server` et l'`obs_server`. Ces instances possèdent une IP publique et sortent sur Internet via l'Internet Gateway (IGW).
- **Subnet Privé :** Héberge le `backend_server` (API). Il est mathématiquement inatteignable depuis l'extérieur. Ses mises à jour sortent via une **NAT Gateway** provisionnée dans le subnet public.

### 2. Le Chaînage de Security Groups (Firewalls)
La sécurité ne repose pas sur le filtrage d'IP locales, mais sur l'identité des composants :
- Le `backend_sg` n'accepte le trafic sur le port 8000 que s'il provient de machines possédant le badge `frontend_sg` ou `obs_sg`.
- Le `obs_sg` (Grafana/Prometheus) applique un **whitelisting strict** (`/32`), limitant l'accès administratif à ma seule adresse IP personnelle.

![Security Group Backend](images/backend_sg_ingress.png)
*(Capture 2 : Règles Ingress du Backend interdisant l'accès public)*

### 3. La Sécurité des Identités (IAM)
Le principe du moindre privilège est appliqué au niveau des machines elles-mêmes :
- **Zéro clé en dur :** Aucune clé d'accès AWS n'est stockée ou injectée sur les serveurs EC2.
- **Instance Profiles :** Le serveur Backend s'authentifie de manière autonome et temporaire auprès des autres services AWS grâce à un rôle IAM dédié (déclaré dans `iam.tf`). Ce rôle lui est attaché via un *Instance Profile*, garantissant une sécurité d'infrastructure optimale.
- **Moindre Privilège :** Une politique stricte en lecture seule (`AmazonS3ReadOnlyAccess`) lui est rattachée, lui permettant de consulter des assets de configuration sans jamais posséder de droits de modification sur l'infrastructure.

![Preuve IAM EC2](images/backend_role.png)
*(Capture : Le serveur Backend (EC2) endossant son identité IAM autonome)*

![Preuve Permissions IAM](images/backend_role_permissions.png)
*(Capture : Les permissions strictes (Read Only) attachées au rôle du Backend)*

### 4. CI/CD & Gestion des Secrets
Le pipeline GitHub Actions valide (`fmt`, `validate`) et planifie le code à chaque push sur la branche `main`. Pour garantir un pipeline **Zero-Trust**, aucune clé AWS n'est codée en dur. L'authentification du runner GitHub se fait via des clés éphémères injectées dynamiquement depuis le coffre-fort chiffré **GitHub Secrets**.

### 5. Infrastructure Immuable (No-SSH)
Les instances EC2 sont déployées de manière entièrement "Headless". Les ports SSH (22) sont fermés et aucune clé de connexion n'est provisionnée. La configuration complète (installation du moteur Docker, injection des variables réseau, lancement des conteneurs) est automatisée à 100% lors du premier démarrage via le processus `cloud-init` (scripts bash `user_data`).

---

## 🛠️ Stack Technique

### Infrastructure & Déploiement
- **Terraform (IaC) :** Déclaration de l'état désiré (HCL) et gestion du *State* distant.
- **AWS S3 & DynamoDB :** Remote Backend pour le stockage du `terraform.tfstate` et le *State Locking* (Disaster Recovery).
- **GitHub Actions :** Pipeline CI/CD pour valider (`fmt`, `validate`) et planifier le code à chaque push.

### Applicatif (Conteneurisation Docker)
- **Frontend :** Vue.js servi par **Nginx** (Reverse Proxy vers l'IP privée du Backend).
- **Backend :** API REST en **Python FastAPI** (générant des métriques standardisées).
- **Observabilité :** Images officielles **Prometheus** (collecte) et **Grafana** (visualisation).

---

## 🚀 Démonstration et Preuves de Concept

### 1. Validation du Flux Applicatif
Le client accède à l'IP publique du Frontend. Nginx intercepte la requête HTTP et fait le pont (Reverse Proxy) vers le réseau privé pour interroger le Backend.

![Interface Frontend Vue.js](images/dashboard_frontend.png)
*(Capture 3 : Le Frontend public affichant la réponse du Backend privé)*

### 2. Observabilité et Télémétrie SRE
Le serveur d'observabilité (Public) parvient à traverser le réseau pour interroger (scrape) l'API privée sur la route `/metrics`.

![Prometheus Targets](images/prometheus_targets.png)
*(Capture 4 : Prometheus confirmant la liaison réseau vers l'API privée (Status: UP))*

Les métriques sont ensuite agrégées et visualisées sur Grafana en temps réel (Taux de réussite HTTP, temps de réponse, consommation CPU/RAM).

![Dashboard Grafana SRE 1](images/obs_1.png)
![Dashboard Grafana SRE 2](images/obs_2.png)
![Dashboard Grafana SRE 3](images/obs_3.png)
*(Captures 5,6,7 : Dashboard Grafana illustrant un test de charge sur l'API)*

---

## 💻 Structure du Dépôt (Bootstrap & Blast Radius)

Pour protéger le coffre-fort Terraform (S3/DynamoDB) d'une destruction accidentelle, le code est partitionné :

```text
.
├── 00-backend/                 # 🔒 BOOTSTRAP (Exécuté 1 fois) : Création S3 & DynamoDB
│   └── backend.tf
│
├── 01-vpc/                     # 🌐 INFRASTRUCTURE RÉSEAU & SERVEURS
│   ├── main.tf                 # VPC, Subnets, Gateways & Déclaration Remote Backend
│   ├── ec2.tf                  # Provisionnement des 3 instances
│   ├── iam.tf                  # Sécurité IAM (Rôles & Policies)
│   ├── observability.tf        # Déploiement Prometheus & Grafana
│   ├── outputs.tf              # Extraction dynamique des IPs publiques
│   └── scripts/
│       ├── script_initialisation_backend.sh    # cloud-init : Docker build Python
│       ├── script_initialisation_frontend.sh   # cloud-init : Docker build Nginx/Vue.js
│       └── script_initialisation_obs.sh        # cloud-init : Docker run Prom/Grafana
│
├── 02-app/                     # 📦 CODE SOURCE APPLICATIF
│   ├── backend/                # Code source FastAPI
│   └── frontend/               # Code source Vue.js
│
└── .github/workflows/ci.yml    # 🤖 PIPELINE CI : terraform validate/plan sur 01-vpc/

## ⚙️ Comment reproduire ce projet (Quick Start)

*Prérequis : AWS CLI authentifié et Terraform installé en local.*

**1. Déployer les fondations (Remote State)**
```bash
cd 00-backend
terraform init
terraform apply -auto-approve

**2. Déployer l'infrastructure réseau et applicative**

```bash
cd ../01-vpc
terraform init
# Les adresses IP publiques de Grafana et du Frontend s'afficheront dans les Outputs.
terraform apply

**3. Nettoyage FinOps (Destruction)**
Pour éviter toute facturation AWS inutile, détruire l'environnement réseau après utilisation :

```bash
terraform destroy

(Note : Ne jamais lancer cette commande dans le dossier 00-backend sous peine de détruire le fichier d'état !)

