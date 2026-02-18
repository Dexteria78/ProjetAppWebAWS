# Phase 4 - Packaging de l'Application avec Docker

## Objectif

Conteneuriser l'application de gestion des étudiants avec Docker et stocker l'image sur Amazon ECR.

## Architecture Phase 4

```
┌─────────────────────────────────────────────┐
│           Amazon ECR Repository             │
│    student-records-app:latest               │
└─────────────────────────────────────────────┘
                    ▲
                    │ docker push
                    │
┌─────────────────────────────────────────────┐
│        Local Docker Build                    │
│  - Dockerfile                                │
│  - Application Node.js + dependencies        │
└─────────────────────────────────────────────┘
                    │
                    ▼ docker pull & run
┌─────────────────────────────────────────────┐
│         Test Environments                    │
│  - Local (Docker Desktop)                    │
│  - EC2 Instance (Docker installed)           │
└─────────────────────────────────────────────┘
```

## Livrables Phase 4

### 1. Dockerfile
- Image de base Node.js
- Installation des dépendances
- Configuration de l'application
- Exposition du port 80
- Variables d'environnement pour la DB

### 2. Infrastructure Terraform
- ECR Repository
- EC2 Instance pour test avec Docker installé
- IAM Roles pour ECR push/pull
- Security Groups

### 3. Scripts
- Build de l'image Docker
- Push vers ECR
- Pull et run sur EC2

## Commandes

```bash
# Build local
docker build -t student-records-app .

# Test local
docker run -p 80:80 \
  -e APP_DB_HOST=<rds-endpoint> \
  -e APP_DB_USER=admin \
  -e APP_DB_PASSWORD=<password> \
  -e APP_DB_NAME=STUDENTS \
  student-records-app

# Push vers ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker tag student-records-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/student-records-app:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/student-records-app:latest
```

## Tests

1. ✅ Build de l'image réussi
2. ✅ Run local avec connexion DB
3. ✅ Push vers ECR
4. ✅ Pull et run sur EC2
5. ✅ Application accessible via EC2

## Points clés

- Image optimisée (multi-stage build si possible)
- Gestion des secrets via variables d'environnement
- Health check dans le Dockerfile
- Tag de version
