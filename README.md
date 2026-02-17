# Projet Capstone - Application de Gestion des Étudiants sur AWS

## Vue d'ensemble du projet

Ce projet capstone démontre l'évolution progressive d'une application web de gestion des étudiants, depuis une architecture monolithique simple jusqu'à une architecture cloud moderne, hautement disponible et conteneurisée.

**Application** : Système de gestion des étudiants permettant de visualiser, ajouter, modifier et supprimer des enregistrements d'étudiants.

**Stack technique** : Node.js + Express + MySQL

---

## Phase 1 - Application Monolithique

### Architecture Phase 1

Architecture simple avec tous les composants sur une seule instance EC2 :
- **VPC** : Réseau virtuel isolé (10.0.0.0/16)
- **1 sous-réseau public** : 10.0.1.0/24 dans us-east-1a
- **Internet Gateway** : Accès Internet
- **EC2 t2.micro** : Serveur web + base de données MySQL locale
- **Security Group** : Règles HTTP (80), SSH (22), MySQL (3306)

### Fichiers Terraform Phase 1

| Fichier | Description |
|---------|-------------|
| **terraform.tf** | Configuration du provider AWS (version ~> 5.0) |
| **variables.tf** | 8 variables : région, nom du projet, environnement, CIDR VPC/subnet, AZ, type d'instance, CIDR SSH autorisé |
| **network.tf** | VPC, Internet Gateway, sous-réseau public avec IPs publiques automatiques, route table avec route par défaut (0.0.0.0/0 → IGW) |
| **security.tf** | Security group avec ingress HTTP:80, SSH:22, MySQL:3306 et egress all traffic |
| **compute.tf** | Data source Ubuntu 22.04 AMI, instance EC2 avec volume root 20GB gp3, userdata pour installation |
| **outputs.tf** | vpc_id, public_subnet_id, web_server_id, public_ip, public_dns, application_url, ssh_command |
| **userdata.sh** | Installation nodejs/npm/mysql-server, téléchargement code depuis S3, création base STUDENTS locale, création utilisateur nodeapp, démarrage application sur port 80 |

### Caractéristiques Phase 1

- ✅ Déploiement simple et rapide (~3 minutes)
- ✅ Coûts minimaux (EC2 t2.micro gratuit)
- ✅ Facile à déboguer (tout sur une machine)

### Vidéos de démonstration Phase 1

📹 **MyDrive** : https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing

- **Vidéo 1** : Destruction de l'ancienne infrastructure
- **Vidéo 2** : Déploiement et test avec ajout d'un étudiant
- **Vidéo 3** : Explication détaillée des fichiers de configuration

### URL de l'application Phase 1
http://34.227.225.16

---

## Phase 2 - Architecture Découplée avec RDS

### Architecture Phase 2

Évolution vers une architecture découplée avec séparation de la base de données :
- **VPC** : Même réseau 10.0.0.0/16
- **3 sous-réseaux** : 1 public + 2 privés dans 2 AZ différentes
- **EC2 t2.micro** : Serveur web uniquement (plus de MySQL local)
- **RDS MySQL 8.0** : Base de données managée (db.t3.micro, 20GB gp3)
- **AWS Secrets Manager** : Stockage sécurisé des credentials
- **Cloud9** : Environnement de développement pour migration
- **3 Security Groups** : Séparation web / RDS / Cloud9

### Fichiers modifiés Phase 1 → Phase 2

| Fichier | Changements |
|---------|-------------|
| **variables.tf** | ➕ 7 nouvelles variables pour RDS et sous-réseaux privés |
| **network.tf** | ➕ 2 sous-réseaux privés dans us-east-1a et us-east-1b |
| **security.tf** | 🔄 3 security groups au lieu de 1 (web, RDS, Cloud9) |
| **compute.tf** | 🔄 Ajout IAM instance profile + depends_on RDS |
| **userdata.sh** | 🔄 Connexion RDS + récupération credentials depuis Secrets Manager |
| **outputs.tf** | ➕ Outputs RDS, Secrets Manager et Cloud9 |

### Nouveaux fichiers Phase 2

| Fichier | Description |
|---------|-------------|
| **database.tf** | Random password, DB subnet group, RDS MySQL instance |
| **secrets.tf** | Secret documentation avec username/password/host/port/dbname |
| **app-secret.tf** | Secret "Mydbsecret" avec structure attendue par l'application (user/password/host/db) |
| **cloud9.tf** | Environnement Cloud9 t3.small pour migration |

### Caractéristiques Phase 2

- ✅ Base de données managée RDS avec backups automatiques
- ✅ Credentials sécurisés dans Secrets Manager
- ✅ Isolation réseau (RDS dans sous-réseaux privés)
- ✅ Multi-AZ capable pour haute disponibilité
- ✅ Security groups granulaires

### Vidéos de démonstration Phase 2

📹 **MyDrive** : https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing

- **Vidéo 1** : Destruction de Phase 2 (si nécessaire)
- **Vidéo 2** : Déploiement Phase 2 et tests avec RDS
- **Vidéo 3** : Explication des fichiers et architecture découplée

### URL de l'application Phase 2
http://35.175.184.177

---

## Troubleshooting

### Phase 1

**L'application ne démarre pas**
- Vérifier les logs : `ssh ubuntu@<IP> && tail -f /var/log/cloud-init-output.log`
- Vérifier MySQL : `systemctl status mysql`

**Erreur de connexion Internet**
- Vérifier la route table (0.0.0.0/0 → IGW)
- Vérifier le security group (HTTP:80 ouvert)

### Phase 2

**Erreur "There was an error retrieving students"**
1. Vérifier que le secret "Mydbsecret" existe
2. Vérifier les security groups (web → RDS autorisé)
3. Vérifier l'endpoint RDS dans les outputs
4. Attendre 2-3 minutes après déploiement (userdata en cours)

**RDS trop lent à créer**
- Normal, prend 5-8 minutes
- Terraform attend automatiquement

**Credentials AWS expirées**
- Retourner sur AWS Academy
- Start Lab → AWS Details → Show
- Copier et exporter les nouvelles credentials

