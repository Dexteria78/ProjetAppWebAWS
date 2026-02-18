#!/bin/bash
set -e

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install MariaDB client for database initialization
yum install -y mariadb105

# Wait for Docker to be fully ready
sleep 10

# Configure AWS CLI region
export AWS_DEFAULT_REGION=${aws_region}

# Get database credentials from Secrets Manager
echo "Retrieving database credentials from Secrets Manager..."
DB_SECRET=$(aws secretsmanager get-secret-value --secret-id ${db_secret_name} --query SecretString --output text)
DB_USER=$(echo $DB_SECRET | jq -r '.username')
DB_PASS=$(echo $DB_SECRET | jq -r '.password')
DB_HOST=$(echo $DB_SECRET | jq -r '.host')
DB_PORT=$(echo $DB_SECRET | jq -r '.port')
DB_NAME=$(echo $DB_SECRET | jq -r '.dbname')

echo "Database host: $DB_HOST"

# Wait for RDS to be available
echo "Waiting for database to be available..."
sleep 30

# Initialize database
echo "Initializing database..."
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME << 'EOSQL'
CREATE TABLE IF NOT EXISTS students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    grade VARCHAR(10) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO students (name, age, grade) VALUES
    ('Alice Johnson', 20, 'A'),
    ('Bob Smith', 22, 'B'),
    ('Charlie Brown', 21, 'A')
ON DUPLICATE KEY UPDATE name=name;
EOSQL

echo "Database initialized successfully"

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repository_uri}

# Pull the Docker image
echo "Pulling Docker image..."
docker pull ${ecr_repository_uri}:latest

# Run the container
echo "Starting application container..."
docker run -d \
  --name student-records-app \
  --restart unless-stopped \
  -p 80:3000 \
  -e DB_HOST=$DB_HOST \
  -e DB_PORT=$DB_PORT \
  -e DB_USER=$DB_USER \
  -e DB_PASSWORD=$DB_PASS \
  -e DB_NAME=$DB_NAME \
  ${ecr_repository_uri}:latest

echo "Application started successfully!"

# Verify the container is running
docker ps

# Setup CloudWatch agent for custom metrics (optional)
echo "Instance initialization complete!"
