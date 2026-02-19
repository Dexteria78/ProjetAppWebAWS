# Phase 2 - Découplage des Composants de l'Application

## 📋 Objectif

Séparer la base de données et l'infrastructure du serveur web de manière à ce qu'elles fonctionnent indépendamment l'une de l'autre. L'application web doit être exécutée sur une machine virtuelle distincte et la base de données doit être exécutée sur l'infrastructure de services gérés (RDS).

## 🎯 Exigences Phase 2

- ✅ Mettre à jour ou recréer les composants du réseau virtuel nécessaires à l'hébergement de la base de données séparément de l'application
- ✅ Créer une base de données Amazon RDS exécutant un moteur MySQL
- ✅ Mettre en service un environnement AWS Cloud9 pour exécuter les commandes AWS CLI
- ✅ Utiliser AWS Secrets Manager pour créer un secret afin de stocker les informations d'identification de la base de données
- ✅ Créer une nouvelle machine virtuelle pour héberger l'application web
- ✅ Migrer les données de la base de données d'origine (EC2) vers la nouvelle base de données Amazon RDS
- ✅ Tester l'application (consulter, ajouter, supprimer et modifier les dossiers des étudiants)

---

## Vue d'ensemble du projet

Cette phase représente l'évolution de l'architecture monolithique de Phase 1 vers une architecture découplée plus robuste et sécurisée. L'application de gestion des étudiants est maintenant connectée à une base de données RDS MySQL managée, avec les credentials stockés de manière sécurisée dans AWS Secrets Manager.

## Architecture

### Composants principaux

- **VPC** : Réseau virtuel isolé (10.0.0.0/16)
- **Sous-réseaux** :
  - 1 sous-réseau public (10.0.1.0/24) pour le serveur web
  - 2 sous-réseaux privés (10.0.2.0/24 et 10.0.3.0/24) pour RDS
- **Internet Gateway** : Accès Internet pour le sous-réseau public
- **EC2 Instance** : Serveur web hébergeant l'application Node.js (t2.micro)
- **RDS MySQL** : Base de données managée (db.t3.micro, 20GB)
- **AWS Secrets Manager** : Stockage sécurisé des credentials de base de données
- **Cloud9** : Environnement de développement pour la migration et l'administration
- **Security Groups** : 3 groupes distincts pour web, RDS et Cloud9

### Changements par rapport à Phase 1

| Aspect | Phase 1 | Phase 2 |
|--------|---------|---------|
| **Base de données** | MySQL local sur EC2 | RDS MySQL managé |
| **Credentials** | Hardcodés dans userdata | AWS Secrets Manager |
| **Réseau** | 1 sous-réseau public | 1 public + 2 privés |
| **Sécurité** | SG unique | 3 SG avec règles spécifiques |
| **High Availability** | Non | RDS Multi-AZ capable |
| **Backups** | Manuel | RDS automatique |
| **Migration** | N/A | Cloud9 pour admin |

## Description des fichiers Terraform

### terraform.tf
Configuration du provider AWS et version requise de Terraform (>= 1.2.0).

### variables.tf
Variables étendues incluant :
- Toutes les variables de Phase 1
- `private_subnet_1_cidr` et `private_subnet_2_cidr` : CIDR des sous-réseaux privés pour RDS
- `availability_zone_2` : Deuxième AZ requise pour le subnet group RDS
- `db_name`, `db_username`, `db_instance_class`, `db_allocated_storage` : Configuration RDS

### network.tf
Infrastructure réseau avec :
- VPC avec DNS activé
- Internet Gateway
- 1 sous-réseau public avec IP publiques automatiques
- 2 sous-réseaux privés dans des AZ différentes (requis pour RDS)
- Route table avec route par défaut vers IGW

### security.tf
3 groupes de sécurité distincts :
- **web_server** : HTTP (80) et SSH (22) depuis Internet
- **rds** : MySQL (3306) uniquement depuis web_server et cloud9 SG
- **cloud9** : Egress only pour les connexions sortantes

### database.tf
Ressources de base de données :
- `random_password` : Génération sécurisée du mot de passe (16 caractères)
- `aws_db_subnet_group` : Groupe de sous-réseaux pour RDS (2 AZ minimum)
- `aws_db_instance` : Instance MySQL 8.0, stockage gp3, pas accessible publiquement

### secrets.tf
Gestion des secrets :
- Secret original pour documentation (`student-records-app-db-credentials-phase2`)
- Référence au LabInstanceProfile existant (AWS Academy)

### app-secret.tf
Secret spécifique pour l'application :
- Nom exact attendu par le code : `Mydbsecret`
- Structure JSON avec clés `user`, `password`, `host`, `db`
- L'application lit automatiquement ce secret au démarrage

### compute.tf
Instance EC2 :
- Utilise le LabInstanceProfile pour accès à Secrets Manager
- Dépend de RDS et des secrets (depends_on)
- Userdata télécharge l'application et crée la table students
- Tags incluent Phase="2"

### cloud9.tf
Environnement Cloud9 :
- Instance t3.small avec Amazon Linux 2023
- Auto-stop après 30 minutes d'inactivité
- Utilisé pour migration et administration de la base de données

### userdata.sh
Script d'initialisation amélioré :
- Installation : nodejs, npm, mysql-client, jq, awscli
- Téléchargement de l'application depuis S3
- Récupération des credentials depuis Secrets Manager
- Création de la table students dans RDS
- Démarrage de l'application avec systemd

### outputs.tf
Sorties étendues incluant :
- Tous les outputs de Phase 1
- IDs des sous-réseaux privés
- Endpoint et adresse RDS
- ARN et nom du secret Secrets Manager
- ID et URL de l'environnement Cloud9

## Déploiement

### Prérequis

1. Credentials AWS Academy valides
2. Terraform >= 1.2.0 installé
3. AWS CLI configuré

### Instructions

```bash
# 1. Se positionner dans le répertoire phase2
cd phase2

# 2. Initialiser Terraform
terraform init

# 3. Vérifier le plan de déploiement
terraform plan

# 4. Appliquer la configuration
terraform apply -auto-approve

# 5. Noter l'URL de l'application dans les outputs
# application_url = "http://X.X.X.X"
```

### Temps de déploiement

- RDS Instance : ~5-8 minutes
- EC2 Instance + userdata : ~2-3 minutes
- **Total : environ 10 minutes**

## Tests et validation

### 1. Page d'accueil
```bash
curl http://<APPLICATION_URL>/
```
Doit afficher "Welcome" et les liens de navigation.

### 2. Liste des étudiants
```bash
curl http://<APPLICATION_URL>/students
```
Doit afficher la table (vide initialement).

### 3. Ajout d'un étudiant
Via l'interface web : cliquer sur "Add Student" et remplir le formulaire.

### 4. Vérification RDS
Les données doivent persister dans RDS (pas sur l'instance EC2).

## Sécurité

### Améliorations implémentées

1. **Isolation réseau** : RDS dans sous-réseaux privés sans accès Internet direct
2. **Secrets Manager** : Credentials jamais exposés dans le code
3. **IAM** : Instance profile avec permissions minimales
4. **Security Groups** : Règles strictes limitant l'accès MySQL
5. **Chiffrement** : RDS utilise le chiffrement au repos par défaut

### Bonnes pratiques

- ✅ Base de données non accessible publiquement
- ✅ Mot de passe généré aléatoirement
- ✅ Credentials récupérés dynamiquement au runtime
- ✅ Security groups avec principe du moindre privilège
- ✅ Multi-AZ capable pour haute disponibilité (désactivé pour coûts)

## Troubleshooting

### L'application affiche une erreur de connexion

1. Vérifier que le secret "Mydbsecret" existe :
```bash
aws secretsmanager get-secret-value --secret-id Mydbsecret --region us-east-1
```

2. Vérifier que l'instance a accès au security group RDS :
```bash
aws ec2 describe-instances --instance-ids <INSTANCE_ID> --query 'Reservations[0].Instances[0].SecurityGroups'
```

3. Vérifier les logs RDS dans la console AWS

### RDS prend trop de temps à démarrer

C'est normal, la création d'une instance RDS prend 5-8 minutes. Terraform attend automatiquement.

### Credentials AWS expirées

AWS Academy expire les credentials toutes les 1-3 heures :
1. Retourner sur AWS Academy
2. Cliquer sur "AWS Details"
3. Copier les nouvelles credentials
4. Les exporter dans le terminal

## Coûts estimés

Avec AWS Academy (compte éducation) :
- **EC2 t2.micro** : Inclus dans le tier gratuit
- **RDS db.t3.micro** : ~$0.017/heure = ~$12/mois
- **Stockage gp3 20GB** : ~$2.3/mois
- **Secrets Manager** : $0.40/secret/mois
- **Cloud9** : Gratuit (utilise EC2 t3.small ~30min/jour)

**Total estimé : ~$15/mois** (mais couvert par les crédits AWS Academy)

## Nettoyage

Pour supprimer toutes les ressources :

```bash
terraform destroy -auto-approve
```

⚠️ **Attention** : RDS a une fenêtre de récupération de 30 jours par défaut. Pour suppression immédiate, utilisez `skip_final_snapshot = true` (déjà configuré).

## Vidéos de démonstration

Les vidéos de déploiement et de test sont disponibles sur MyDrive :
https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing

## Prochaines étapes (Phase 3)

- Ajout d'un Application Load Balancer
- Configuration d'Auto Scaling Group
- Tests de charge avec loadtest
- Haute disponibilité avec minimum 2 instances

## Ressources

- [Documentation Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
