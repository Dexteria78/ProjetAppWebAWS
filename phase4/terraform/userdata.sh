#!/bin/bash
# User data script pour installer Docker et deployer l'application
# Ce script s'execute automatiquement au demarrage de l'instance EC2

set -e

# Variables passees par Terraform
ECR_REPOSITORY_URL="${ecr_repository_url}"
AWS_REGION="${aws_region}"
DB_SECRET_NAME="${db_secret_name}"

# Log file
LOG_FILE="/var/log/userdata.log"
exec > >(tee -a $LOG_FILE) 2>&1

echo "=================================================="
echo "Starting userdata script at $(date)"
echo "=================================================="

# Mise a jour du systeme
echo "Updating system packages..."
dnf update -y

# Installation de Docker
echo "Installing Docker..."
dnf install -y docker

# Demarrer et activer Docker
echo "Starting Docker service..."
systemctl start docker
systemctl enable docker

# Ajouter ec2-user au groupe docker
usermod -a -G docker ec2-user

# Installation de AWS CLI v2 (si pas deja installe)
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI v2..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    dnf install -y unzip
    unzip awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
fi

# Installation de jq pour parser le JSON
echo "Installing jq..."
dnf install -y jq

# Attendre que Docker soit pret
echo "Waiting for Docker to be ready..."
until docker info > /dev/null 2>&1; do
    echo "Waiting for Docker daemon to start..."
    sleep 2
done

echo "Docker is ready!"

# Recuperer les credentials de la base de donnees depuis Secrets Manager
echo "Retrieving database credentials from Secrets Manager..."
DB_CREDENTIALS=$(aws secretsmanager get-secret-value \
    --secret-id "$DB_SECRET_NAME" \
    --region "$AWS_REGION" \
    --query SecretString \
    --output text)

DB_HOST=$(echo $DB_CREDENTIALS | jq -r '.host')
DB_PORT=$(echo $DB_CREDENTIALS | jq -r '.port')
DB_USER=$(echo $DB_CREDENTIALS | jq -r '.username')
DB_PASSWORD=$(echo $DB_CREDENTIALS | jq -r '.password')
DB_NAME=$(echo $DB_CREDENTIALS | jq -r '.dbname')

echo "Database endpoint: $DB_HOST:$DB_PORT"

# Attendre que RDS soit probablement pret (pas de nc disponible dans Amazon Linux 2023)
echo "Waiting 30 seconds for RDS database to become ready..."
sleep 30
echo "Proceeding with database initialization..."

# Installer mysql client pour initialiser la base de donnees
echo "Installing MySQL client..."
dnf install -y mariadb105 > /dev/null 2>&1

# Initialiser la base de donnees avec la table students et des donnees de test
echo "Initializing database schema and data..."
cat > /tmp/init_db.sql << 'EOF'
CREATE TABLE IF NOT EXISTS students (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255),
  address VARCHAR(255),
  city VARCHAR(255),
  state VARCHAR(255),
  email VARCHAR(255),
  phone VARCHAR(255)
);

DELETE FROM students;

INSERT INTO students (name, address, city, state, email, phone) VALUES 
  ('Alice Martin', '123 Rue de Paris', 'Paris', 'Ile-de-France', 'alice.martin@email.fr', '01 23 45 67 89'),
  ('Bob Dupont', '456 Avenue de Lyon', 'Lyon', 'Auvergne-Rhone-Alpes', 'bob.dupont@email.fr', '04 56 78 90 12'),
  ('Charlie Durand', '789 Boulevard de Marseille', 'Marseille', 'PACA', 'charlie.durand@email.fr', '04 91 23 45 67');
EOF

# Executer le script d'initialisation
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME < /tmp/init_db.sql 2>&1 | tee -a $LOG_FILE

if [ $? -eq 0 ]; then
    echo "Database initialized successfully!"
else
    echo "Warning: Database initialization failed, but continuing..."
fi

echo "Proceeding with container deployment..."

# Authentification a ECR
echo "Authenticating to ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin $ECR_REPOSITORY_URL

# Attendre que l'image soit disponible dans ECR
echo "Checking if image is available in ECR..."
MAX_WAIT=300  # 5 minutes max
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if docker pull $ECR_REPOSITORY_URL:latest 2>/dev/null; then
        echo "Image successfully pulled from ECR!"
        break
    else
        echo "Image not yet available in ECR, waiting... ($WAITED/$MAX_WAIT seconds)"
        sleep 10
        WAITED=$((WAITED+10))
    fi
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo "WARNING: Image not available in ECR after $MAX_WAIT seconds"
    echo "You may need to manually push the image and restart the container"
    exit 0
fi

# Arreter et supprimer le container existant si present
echo "Stopping and removing existing container if present..."
docker stop student-records-app 2>/dev/null || true
docker rm student-records-app 2>/dev/null || true

# Demarrer le container avec les variables d'environnement
echo "Starting application container..."
docker run -d \
    --name student-records-app \
    --restart unless-stopped \
    -p 80:3000 \
    -e NODE_ENV=production \
    -e APP_PORT=3000 \
    -e APP_DB_HOST=$DB_HOST \
    -e APP_DB_USER=$DB_USER \
    -e APP_DB_PASSWORD=$DB_PASSWORD \
    -e APP_DB_NAME=$DB_NAME \
    $ECR_REPOSITORY_URL:latest

# Verifier que le container tourne
echo "Checking container status..."
sleep 5
docker ps -a | grep student-records-app

# Afficher les logs du container
echo "Container logs:"
docker logs student-records-app

echo "=================================================="
echo "Userdata script completed at $(date)"
echo "=================================================="
echo ""
echo "To check application status:"
echo "  docker ps"
echo "  docker logs student-records-app"
echo "  curl http://localhost:80"
