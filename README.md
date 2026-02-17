# Projet Capstone - Application de Gestion des Étudiants sur AWS

## Vue d'ensemble du projet

Ce projet capstone démontre l'évolution progressive d'une application web de gestion des étudiants, depuis une architecture monolithique simple jusqu'à une architecture cloud moderne, hautement disponible et conteneurisée.

**Application** : Système de gestion des étudiants permettant de visualiser, ajouter, modifier et supprimer des enregistrements d'étudiants.

**Stack technique** : Node.js + Express + MySQL

**Phases du projet** :
- ✅ **Phase 1** : Application monolithique (EC2 + MySQL local)
- ✅ **Phase 2** : Architecture découplée (RDS + Secrets Manager)
- 🔜 **Phase 3** : Haute disponibilité (Load Balancer + Auto Scaling)
- 🔜 **Phase 4** : Conteneurisation (Docker + ECR)
- 🔜 **Phase 5** : CI/CD Pipeline
- 🔜 **Phase 6** : Orchestration de conteneurs (ECS/EKS)
- 🔜 **Phase 7** : Améliorations et optimisations

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
- ⚠️ Base de données non managée (backups manuels)
- ⚠️ Credentials hardcodés dans userdata
- ⚠️ Pas de haute disponibilité
- ⚠️ Scaling vertical uniquement

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
- ⚠️ Temps de déploiement plus long (~10 minutes)
- ⚠️ Coûts plus élevés (~$15/mois vs ~$2/mois)

### Vidéos de démonstration Phase 2

📹 **MyDrive** : https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing

- **Vidéo 1** : Destruction de Phase 2 (si nécessaire)
- **Vidéo 2** : Déploiement Phase 2 et tests avec RDS
- **Vidéo 3** : Explication des fichiers et architecture découplée

### URL de l'application Phase 2
http://35.175.184.177

---

## Déploiement

### Prérequis

1. **AWS Academy Learner Lab**
   - Credentials valides (expirent toutes les 1-3 heures)
   - Renouvellement : AWS Academy → Modules → Learner Lab → Start Lab → AWS Details → Show

2. **Outils locaux**
   - Terraform >= 1.2.0
   - AWS CLI >= 2.0
   - Git

### Instructions Phase 1

```bash
cd phase1
terraform init
terraform plan
terraform apply -auto-approve
# Noter l'application_url dans les outputs
```

### Instructions Phase 2

```bash
cd phase2
terraform init
terraform plan
terraform apply -auto-approve
# Attendre ~10 minutes pour le déploiement complet de RDS
# Tester : curl http://<APPLICATION_URL>/students
```

### Destruction

```bash
# Dans le répertoire de la phase concernée
terraform destroy -auto-approve
```

⚠️ **Important** : Détruire Phase 2 avant Phase 1 si les deux sont déployés (dépendance VPC).

---

## Tests et validation

### Phase 1 - Tests monolithique

```bash
# Page d'accueil
curl http://<IP>/

# Liste des étudiants
curl http://<IP>/students

# Vérifier que MySQL est local
ssh -i key.pem ubuntu@<IP>
mysql -u nodeapp -pstudent12 -e "SELECT * FROM STUDENTS.students"
```

### Phase 2 - Tests avec RDS

```bash
# Page d'accueil
curl http://<IP>/

# Liste des étudiants (doit afficher tableau vide initialement)
curl http://<IP>/students

# Ajouter un étudiant via l'interface web
# Vérifier la persistance des données dans RDS
```

**Validation Phase 2** : Les données doivent persister dans RDS, pas sur l'instance EC2. Si l'instance est détruite et recréée, les données restent.

---

## Comparaison des architectures

| Aspect | Phase 1 | Phase 2 |
|--------|---------|---------|
| **Nombre de ressources** | 8 | 22 |
| **Sous-réseaux** | 1 public | 1 public + 2 privés |
| **Base de données** | MySQL local | RDS MySQL managé |
| **Credentials** | Hardcodés | Secrets Manager |
| **Security Groups** | 1 (permissif) | 3 (restrictifs) |
| **IAM** | Aucun | Instance Profile |
| **Haute dispo** | Non | Multi-AZ capable |
| **Backups** | Manuels | RDS automatiques |
| **Temps de déploiement** | ~3 min | ~10 min |
| **Coût mensuel** | ~$0 | ~$15 |
| **Complexité** | Faible | Moyenne |

---

## Structure du projet

```
student-records-app-capstone/
├── README.md                    # Ce fichier
├── .gitignore                   # Exclut .terraform/, *.tfstate, *.zip
├── phase1/
│   ├── terraform.tf
│   ├── variables.tf
│   ├── network.tf
│   ├── security.tf
│   ├── compute.tf
│   ├── outputs.tf
│   ├── userdata.sh
│   └── README.md                # Documentation spécifique Phase 1
└── phase2/
    ├── terraform.tf             # Identique Phase 1
    ├── variables.tf             # ➕ Variables RDS
    ├── network.tf               # ➕ 2 sous-réseaux privés
    ├── security.tf              # 🔄 3 SG au lieu de 1
    ├── compute.tf               # 🔄 IAM profile + depends_on
    ├── database.tf              # ➕ NOUVEAU
    ├── secrets.tf               # ➕ NOUVEAU
    ├── app-secret.tf            # ➕ NOUVEAU (Mydbsecret)
    ├── cloud9.tf                # ➕ NOUVEAU
    ├── outputs.tf               # ➕ Outputs RDS/Secrets/Cloud9
    ├── userdata.sh              # 🔄 Connexion RDS + Secrets Manager
    └── README.md                # Documentation spécifique Phase 2
```

**Légende** :
- ➕ Nouveau fichier/fonctionnalité
- 🔄 Fichier modifié avec changements
- Identique : Aucun changement

---

## Sécurité

### Bonnes pratiques implémentées

#### Phase 1
- ✅ VPC isolé
- ✅ Security group avec règles définies
- ⚠️ Credentials en clair dans userdata

#### Phase 2
- ✅ Tout Phase 1 +
- ✅ RDS dans sous-réseaux privés (pas d'accès Internet direct)
- ✅ Secrets Manager (credentials jamais en clair)
- ✅ IAM instance profile (principe du moindre privilège)
- ✅ 3 security groups avec règles strictes
- ✅ MySQL accessible uniquement depuis web server et Cloud9
- ✅ Chiffrement RDS au repos activé par défaut

### Améliorations de sécurité Phase 1 → Phase 2

1. **Isolation réseau** : Base de données dans sous-réseaux privés
2. **Gestion des secrets** : Secrets Manager au lieu de hardcoding
3. **Contrôle d'accès** : Security groups granulaires
4. **Traçabilité** : IAM pour auditer les accès
5. **Chiffrement** : RDS chiffré automatiquement

---

## Coûts estimés

### Phase 1
- **EC2 t2.micro** : Gratuit (tier gratuit AWS)
- **Stockage EBS 20GB** : $2/mois
- **Transfert données** : Négligeable
- **Total** : **~$2/mois**

### Phase 2
- **EC2 t2.micro** : Gratuit (tier gratuit)
- **RDS db.t3.micro** : $0.017/h = ~$12/mois
- **Stockage RDS 20GB** : $2.3/mois
- **Secrets Manager** : $0.40/secret × 2 = $0.80/mois
- **Cloud9** : Gratuit (utilise EC2 t3.small ~30min/jour)
- **Total** : **~$15/mois**

💡 **Note** : Avec AWS Academy, les crédits couvrent ces coûts.

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

---

## Prochaines étapes

### Phase 3 - Haute Disponibilité
- Application Load Balancer (ALB)
- Auto Scaling Group (2-5 instances)
- Launch Template
- Tests de charge avec loadtest

📹 **MyDrive** : https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing
- **Vidéo 1** : Destruction de Phase 3 (si nécessaire)
- **Vidéo 2** : Déploiement Phase 3 et tests de charge
- **Vidéo 3** : Explication Load Balancer et Auto Scaling

### Phase 4 - Conteneurisation
- Dockerfile pour l'application Node.js
- Amazon ECR (Elastic Container Registry)
- Push/Pull d'images
- Déploiement conteneurisé

📹 **MyDrive** : https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing
- **Vidéo 1** : Destruction de Phase 4 (si nécessaire)
- **Vidéo 2** : Build et déploiement avec Docker
- **Vidéo 3** : Explication Dockerfile et ECR

### Phase 5 - CI/CD
- Pipeline automatisé (GitHub Actions / AWS CodePipeline)
- Build → Test → Package → Deploy
- Tests de charge automatiques

📹 **MyDrive** : https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing
- **Vidéo 1** : Destruction de Phase 5 (si nécessaire)
- **Vidéo 2** : Configuration et exécution du pipeline
- **Vidéo 3** : Explication CI/CD et automatisation

### Phase 6 - Orchestration
- Amazon ECS ou EKS
- Gestion de plusieurs conteneurs
- Rolling updates
- Health checks avancés

📹 **MyDrive** : https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing
- **Vidéo 1** : Destruction de Phase 6 (si nécessaire)
- **Vidéo 2** : Déploiement ECS/EKS
- **Vidéo 3** : Explication orchestration de conteneurs

### Phase 7 - Améliorations
- CloudWatch monitoring & alarms
- CloudFront CDN
- WAF (Web Application Firewall)
- Multi-région pour disaster recovery
- Authentification (Cognito)

📹 **MyDrive** : https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing
- **Vidéo 1** : Destruction de Phase 7 (si nécessaire)
- **Vidéo 2** : Déploiement des améliorations
- **Vidéo 3** : Explication optimisations et best practices

---

## Vidéos de démonstration

📹 **Toutes les vidéos sont disponibles sur MyDrive** :
https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing

Chaque phase comprend 3 vidéos :
- **Vidéo 1** : Destruction de l'infrastructure précédente (si nécessaire)
- **Vidéo 2** : Déploiement et tests de la phase
- **Vidéo 3** : Explication détaillée des fichiers et de l'architecture

---

## Ressources

### Documentation officielle
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
- [AWS VPC Guide](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)

### Outils utilisés
- Terraform v1.14.5
- AWS Provider v5.100.0
- AWS CLI v2.31.32
- Node.js (dernière LTS)
- MySQL 8.0

---

## Auteur

**Nicolas Guérin**
- Projet Capstone - Supdevinci-edu.fr
- Repository GitHub : [ProjetAppWebAWS](https://github.com/Dexteria78/ProjetAppWebAWS)
- Date : Février 2026

---

## Licence

Projet éducatif - AWS Academy Learner Lab
