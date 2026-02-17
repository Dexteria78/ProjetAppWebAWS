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

### URL de l'application Phase 1
http://34.227.225.16 (déploiement initial)

---

## Phase 2 - Architecture Découplée avec RDS

### Architecture Phase 2

Évolution vers une architecture découplée avec séparation de la base de données :
- **VPC** : Même réseau 10.0.0.0/16
- **3 sous-réseaux** :
  - 1 public (10.0.1.0/24) pour le serveur web
  - 2 privés (10.0.2.0/24, 10.0.3.0/24) pour RDS dans 2 AZ différentes
- **Internet Gateway** : Inchangé
- **EC2 t2.micro** : Serveur web uniquement (plus de MySQL local)
- **RDS MySQL 8.0** : Base de données managée (db.t3.micro, 20GB gp3)
- **AWS Secrets Manager** : Stockage sécurisé des credentials
- **Cloud9** : Environnement de développement pour migration
- **3 Security Groups** : Séparation web / RDS / Cloud9

### Fichiers modifiés Phase 1 → Phase 2

| Fichier | Changements |
|---------|-------------|
| **variables.tf** | ➕ `private_subnet_1_cidr`, `private_subnet_2_cidr`, `availability_zone_2`, `db_name`, `db_username`, `db_instance_class`, `db_allocated_storage` |
| **network.tf** | ➕ 2 sous-réseaux privés (`aws_subnet.private_1`, `aws_subnet.private_2`) sans IPs publiques |
| **security.tf** | 🔄 Security group web (retrait de MySQL:3306)<br>➕ Security group RDS (MySQL:3306 depuis web et Cloud9 uniquement)<br>➕ Security group Cloud9 (egress only) |
| **compute.tf** | 🔄 Ajout de `iam_instance_profile` (LabInstanceProfile pour AWS Academy)<br>🔄 Ajout de `depends_on` (RDS et Secrets Manager)<br>🔄 Tags incluent `Phase = "2"` |
| **userdata.sh** | 🔄 Retrait installation mysql-server<br>➕ Installation mysql-client, jq, awscli<br>🔄 Récupération credentials depuis Secrets Manager<br>🔄 Connexion à RDS distant (pas localhost)<br>➕ Configuration systemd pour démarrage automatique |
| **outputs.tf** | ➕ `private_subnet_1_id`, `private_subnet_2_id`, `rds_endpoint`, `rds_address`, `secrets_manager_arn`, `secrets_manager_name`, `cloud9_environment_id`, `cloud9_url` |

### Nouveaux fichiers Phase 2

| Fichier | Description |
|---------|-------------|
| **database.tf** | `random_password` (16 caractères), `aws_db_subnet_group` (2 sous-réseaux requis), `aws_db_instance` (MySQL 8.0, non public, single-AZ pour coûts) |
| **secrets.tf** | `aws_secretsmanager_secret` (student-records-app-db-credentials-phase2), `aws_secretsmanager_secret_version` (JSON avec username, password, host, port, dbname), référence LabInstanceProfile |
| **app-secret.tf** | **Secret spécifique pour l'application** : `Mydbsecret` (nom exact attendu par le code Node.js), structure JSON avec clés `user`, `password`, `host`, `db` (différent du secret documentation) |
| **cloud9.tf** | `aws_cloud9_environment_ec2` (t3.small, Amazon Linux 2023, auto-stop 30min, dans sous-réseau public) |

### Évolution de l'architecture

#### Base de données
- **Phase 1** : MySQL installé localement sur EC2 avec userdata
- **Phase 2** : RDS MySQL 8.0 managé dans sous-réseaux privés

#### Sécurité des credentials
- **Phase 1** : Hardcodés dans userdata (`student12` visible en clair)
- **Phase 2** : Générés aléatoirement et stockés dans Secrets Manager

#### Réseau
- **Phase 1** : 1 sous-réseau public (tout accessible depuis Internet)
- **Phase 2** : 1 public + 2 privés (RDS isolé, accessible uniquement par web server)

#### Security Groups
- **Phase 1** : 1 SG unique pour tout
- **Phase 2** : 3 SG distincts avec principe du moindre privilège

#### IAM
- **Phase 1** : Pas de rôle IAM
- **Phase 2** : Instance profile pour accès sécurisé à Secrets Manager

#### Haute disponibilité
- **Phase 1** : Aucune (instance unique, DB locale)
- **Phase 2** : RDS Multi-AZ capable (désactivé pour coûts mais infrastructure prête)

#### Backups
- **Phase 1** : Aucun (données perdues si instance détruite)
- **Phase 2** : RDS automated backups (désactivé pour coûts mais configurable)

### Point technique important - Secret "Mydbsecret"

L'application Node.js cherche un secret nommé **exactement** `Mydbsecret` avec cette structure :
```json
{
  "user": "admin",
  "password": "generated_password",
  "host": "rds-endpoint.amazonaws.com",
  "db": "STUDENTS"
}
```

C'est pourquoi nous avons créé `app-secret.tf` en plus de `secrets.tf`. Le premier est pour l'application, le second pour la documentation et traçabilité.

### URL de l'application Phase 2
http://35.175.184.177

### Temps de déploiement Phase 2
- **RDS** : ~5-8 minutes (création de l'instance managée)
- **EC2 + userdata** : ~2-3 minutes
- **Total** : ~10 minutes

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

### Phase 4 - Conteneurisation
- Dockerfile pour l'application Node.js
- Amazon ECR (Elastic Container Registry)
- Push/Pull d'images
- Déploiement conteneurisé

### Phase 5 - CI/CD
- Pipeline automatisé (GitHub Actions / AWS CodePipeline)
- Build → Test → Package → Deploy
- Tests de charge automatiques

### Phase 6 - Orchestration
- Amazon ECS ou EKS
- Gestion de plusieurs conteneurs
- Rolling updates
- Health checks avancés

### Phase 7 - Améliorations
- CloudWatch monitoring & alarms
- CloudFront CDN
- WAF (Web Application Firewall)
- Multi-région pour disaster recovery
- Authentification (Cognito)

---

## Vidéos de démonstration

Toutes les vidéos de déploiement et tests sont disponibles sur MyDrive :
https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing

**Contenu des vidéos Phase 1** :
- Vidéo 1 : Destruction de l'ancienne infrastructure
- Vidéo 2 : Déploiement et test avec ajout d'étudiant
- Vidéo 3 : Explication des fichiers de configuration

**Contenu des vidéos Phase 2** (à venir) :
- Déploiement avec RDS
- Configuration Secrets Manager
- Tests de persistance des données
- Utilisation de Cloud9

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
