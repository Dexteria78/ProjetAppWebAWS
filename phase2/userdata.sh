#!/bin/bash -xe
apt update -y
apt install nodejs unzip wget npm mysql-client jq awscli -y
#wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACCAP1-1-DEV/code.zip -P /home/ubuntu
wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACCAP1-1-91571/1-lab-capstone-project-1/code.zip -P /home/ubuntu
cd /home/ubuntu
unzip code.zip -x "resources/codebase_partner/node_modules/*"
cd resources/codebase_partner
npm install aws-sdk

# Récupération des credentials depuis Secrets Manager
SECRET_NAME="student-records-app-db-credentials-phase2"
REGION="us-east-1"
SECRET=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $REGION --query SecretString --output text)

# Extraction des valeurs
DB_HOST=$(echo $SECRET | jq -r .host)
DB_USER=$(echo $SECRET | jq -r .username)
DB_PASSWORD=$(echo $SECRET | jq -r .password)
DB_NAME=$(echo $SECRET | jq -r .dbname)

# Création de la table students dans RDS si elle n'existe pas
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME << 'EOF'
CREATE TABLE IF NOT EXISTS students (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  address VARCHAR(255),
  city VARCHAR(255),
  state VARCHAR(255),
  email VARCHAR(255),
  phone VARCHAR(255)
);
EOF

# Création d'un fichier .env pour l'application Node.js
cat > /home/ubuntu/resources/codebase_partner/.env << ENV
APP_DB_HOST=$DB_HOST
APP_DB_USER=$DB_USER
APP_DB_PASSWORD=$DB_PASSWORD
APP_DB_NAME=$DB_NAME
APP_PORT=80
ENV

# Installation de dotenv pour lire le fichier .env
cd /home/ubuntu/resources/codebase_partner
npm install dotenv

# Démarrage de l'application en arrière-plan
cd /home/ubuntu/resources/codebase_partner
APP_DB_HOST=$DB_HOST APP_DB_USER=$DB_USER APP_DB_PASSWORD=$DB_PASSWORD APP_DB_NAME=$DB_NAME APP_PORT=80 npm start &

# Configuration du démarrage automatique
cat > /etc/systemd/system/student-app.service << 'SERVICE'
[Unit]
Description=Student Records Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/resources/codebase_partner
Environment="APP_DB_HOST=${DB_HOST}"
Environment="APP_DB_USER=${DB_USER}"
Environment="APP_DB_PASSWORD=${DB_PASSWORD}"
Environment="APP_DB_NAME=${DB_NAME}"
Environment="APP_PORT=80"
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

# Remplacement des placeholders dans le service
sed -i "s|\${DB_HOST}|$DB_HOST|g" /etc/systemd/system/student-app.service
sed -i "s|\${DB_USER}|$DB_USER|g" /etc/systemd/system/student-app.service
sed -i "s|\${DB_PASSWORD}|$DB_PASSWORD|g" /etc/systemd/system/student-app.service
sed -i "s|\${DB_NAME}|$DB_NAME|g" /etc/systemd/system/student-app.service

systemctl daemon-reload
systemctl enable student-app.service
systemctl start student-app.service
