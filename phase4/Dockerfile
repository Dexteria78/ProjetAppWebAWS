# Phase 4 - Dockerfile pour l'application de gestion des étudiants
# Image de base Node.js 18 (LTS) sur Alpine pour une image légère
FROM node:18-alpine AS base

# Métadonnées
LABEL maintainer="student-records-app"
LABEL version="1.0"
LABEL description="Application de gestion des étudiants avec Node.js et MySQL"

# Définir le répertoire de travail
WORKDIR /app

# Phase 1: Installation des dépendances
FROM base AS dependencies

# Copier les fichiers de dépendances
COPY resources/codebase_partner/package*.json ./

# Installer les dépendances de production uniquement
RUN npm ci --only=production --quiet

# Phase 2: Build final
FROM base AS release

# Créer un utilisateur non-root pour la sécurité
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copier les dépendances depuis l'étape précédente
COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copier le code de l'application
COPY --chown=nodejs:nodejs resources/codebase_partner/ ./

# Variables d'environnement par défaut (peuvent être override au runtime)
ENV NODE_ENV=production
ENV APP_PORT=80
ENV APP_DB_HOST=localhost
ENV APP_DB_USER=admin
ENV APP_DB_PASSWORD=changeme
ENV APP_DB_NAME=STUDENTS

# Exposer le port de l'application
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:80/', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Passer à l'utilisateur non-root
USER nodejs

# Commande de démarrage
CMD ["node", "index.js"]
