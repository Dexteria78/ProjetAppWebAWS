# Phase 6 : Ajout d'un Orchestrateur de Conteneurs

## Objectif

Passer à un déploiement avec un orchestrateur de conteneurs pour une gestion avancée et une haute disponibilité.

## Exigences Phase 6

- Déployer l'application sur **Amazon ECS** (EC2), **Amazon EKS** (Kubernetes) ou utiliser un autre orchestrateur
- Configurer l'orchestration des conteneurs pour la haute disponibilité
- Implémenter l'auto-scaling avec l'orchestrateur
- Intégrer avec Application Load Balancer
- Mettre en place le monitoring et les alertes

---

## Vue d'ensemble Détaillée

Cette phase implémente une **architecture hautement disponible et auto-scalable** pour l'application Student Records avec :
- **Application Load Balancer (ALB)** multi-AZ
- **Auto Scaling Group (ASG)** avec scaling automatique
- **RDS Multi-AZ** pour la haute disponibilité de la base de données
- **CloudWatch** monitoring et alertes
- **Target Tracking** et scaling policies avancées

## Architecture

```
                    
                       Internet      
                    
                             
                    
                      Application    
                      Load Balancer   (Multi-AZ)
                    
                             
        
                                                
                     
      EC2               EC2               EC2   
    (AZ-1)            (AZ-2)            (AZ-3)  
    Docker            Docker            Docker  
                     
                                              
        
                            
                   
                      RDS MySQL     
                      Multi-AZ      
                     (Primary+      
                      Standby)      
                   
                            
                   
                    Secrets Manager 
                    (DB Credentials)
                   

        
              CloudWatch Monitoring       
          • Metrics  • Alarms             
          • Dashboard  • Auto Scaling     
        
```

## Fonctionnalités

### High Availability (HA)
- **Multi-AZ RDS** : Réplication synchrone avec failover automatique
- **ALB Multi-AZ** : Distribution du trafic sur plusieurs zones
- **Auto Healing** : Remplacement automatique des instances défaillantes
- **Health Checks** : Détection proactive des problèmes

### Auto-Scaling
- **Min/Max Instances** : 2-4 instances configurables
- **CPU-based Scaling** : Scale up > 70%, scale down < 30%
- **Target Tracking** : Maintient 50% CPU automatiquement
- **Cooldown Period** : 5 minutes entre chaque scaling

### Monitoring & Alertes
- **CloudWatch Dashboard** : Vue complète (ALB, ASG, RDS)
- **Alarmes CPU** : Notifications sur seuils critiques
- **Unhealthy Hosts** : Alerte si instances malsaines
- **RDS Monitoring** : CPU, connexions, mémoire

## Déploiement

### 1. Prérequis

```bash
# Naviguer vers le répertoire
cd /home/nicog/aws/student-records-app-capstone/phase6/terraform

# Vérifier les fichiers
ls -la
# main.tf  variables.tf  outputs.tf  userdata.sh
```

### 2. Construire et pousser l'image Docker vers ECR

```bash
# Retourner à phase4 pour le build
cd ../../phase4

# Login à ECR (remplacer ACCOUNT_ID et REGION)
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build l'image
docker build -t student-records-app .

# Tag l'image
docker tag student-records-app:latest \
  <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/student-records-app:latest

# Push vers ECR (sera créé automatiquement par Terraform)
# Cette commande échouera jusqu'à ce que Terraform crée le repo
```

### 3. Initialiser et déployer Terraform

```bash
cd ../phase6/terraform

# Initialiser Terraform
terraform init

# Vérifier le plan
terraform plan

# Déployer l'infrastructure
terraform apply -auto-approve
```

### 4. Attendre le déploiement complet

```
⏱  Temps estimé : 12-15 minutes
  - RDS Multi-AZ : ~10 min
  - ALB + Target Group : ~2 min
  - ASG + Instances : ~3 min
```

### 5. Récupérer l'URL de l'application

```bash
# Obtenir l'URL du Load Balancer
terraform output application_url

# Exemple de sortie :
# http://student-records-alb-phase6-123456789.us-east-1.elb.amazonaws.com
```

### 6. Vérifier le déploiement

```bash
# Tester l'endpoint
APP_URL=$(terraform output -raw application_url)
curl $APP_URL/students

# Vérifier le nombre d'instances
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names student-records-asg-phase6 \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,HealthStatus,AvailabilityZone]' \
  --output table
```

## Configuration Auto-Scaling

### Configuration par défaut

| Paramètre           | Valeur  | Description                    |
|---------------------|---------|--------------------------------|
| Min Instances       | 2       | Toujours au moins 2 instances  |
| Max Instances       | 4       | Maximum 4 instances            |
| Desired Capacity    | 2       | Démarrage avec 2 instances     |
| Health Check Type   | ELB     | Basé sur ALB target group      |
| Grace Period        | 300s    | Attente avant premier check    |

### Scaling Policies

#### 1. Target Tracking (Principal)
```
Métrique : CPU moyenne de l'ASG
Cible    : 50%
Action   : Ajuste automatiquement le nombre d'instances
```

#### 2. Scale UP (Simple Scaling)
```
Condition : CPU > 70% pendant 2 minutes
Action    : Ajouter 1 instance
Cooldown  : 300 secondes
```

#### 3. Scale DOWN (Simple Scaling)
```
Condition : CPU < 30% pendant 2 minutes
Action    : Retirer 1 instance
Cooldown  : 300 secondes
```

### Personnaliser le scaling

Éditer [terraform/variables.tf](terraform/variables.tf) :

```hcl
variable "asg_min_size" {
  default     = 3  # Augmenter le minimum
}

variable "asg_max_size" {
  default     = 6  # Augmenter le maximum
}
```

Appliquer les changements :
```bash
terraform apply -auto-approve
```

## Tests de Charge

### Test 1 : Load test basique

```bash
# Installer Apache Bench
sudo apt-get install -y apache2-utils  # Ubuntu/Debian
# ou
sudo yum install -y httpd-tools        # Amazon Linux

# Obtenir l'URL
APP_URL=$(terraform output -raw application_url)

# Test de charge : 1000 requêtes, 50 concurrent
ab -n 1000 -c 50 $APP_URL/students
```

**Résultats attendus :**
```
Requests per second:    100-150 [#/sec]
Time per request:       300-500 [ms]
Failed requests:        0
```

### Test 2 : Déclencher le scaling

```bash
# Test intensif pour forcer le scale-up
# 5000 requêtes, 100 concurrent pendant plusieurs minutes
for i in {1..5}; do
  echo "Round $i/5"
  ab -n 5000 -c 100 $APP_URL/students
  sleep 10
done
```

**Observer le scaling :**
```bash
# Surveiller les instances en temps réel
watch -n 5 'aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names student-records-asg-phase6 \
  --query "AutoScalingGroups[0].[DesiredCapacity,MinSize,MaxSize]" \
  --output table'
```

### Test 3 : Simuler une panne

```bash
# Arrêter une instance pour tester l'auto-healing
INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names student-records-asg-phase6 \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
  --output text)

# Terminer l'instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Observer le remplacement automatique
watch -n 5 'aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names student-records-asg-phase6 \
  --query "AutoScalingGroups[0].Instances[*].[InstanceId,HealthStatus,LifecycleState]" \
  --output table'
```

**Résultat attendu :** ASG lance automatiquement une nouvelle instance en ~3 minutes

## Monitoring CloudWatch

### Accéder au Dashboard

```bash
# Obtenir l'URL du dashboard
terraform output cloudwatch_dashboard_url

# Ou via AWS Console
# CloudWatch → Dashboards → student-records-dashboard-phase6
```

### Métriques surveillées

#### Application Load Balancer
- **TargetResponseTime** : Temps de réponse des instances
- **RequestCount** : Nombre total de requêtes
- **HTTPCode_Target_2XX_Count** : Requêtes réussies
- **HTTPCode_Target_5XX_Count** : Erreurs serveur

#### Auto Scaling Group
- **CPUUtilization** : Utilisation CPU moyenne
- **GroupDesiredCapacity** : Nombre d'instances désiré
- **GroupInServiceInstances** : Instances en service
- **GroupMinSize/MaxSize** : Limites configurées

#### RDS Database
- **DatabaseConnections** : Connexions actives
- **CPUUtilization** : CPU de la base de données
- **FreeableMemory** : Mémoire disponible

### Alarmes configurées

| Alarme                    | Condition          | Action                    |
|---------------------------|--------------------|---------------------------|
| cpu-high                  | CPU > 70% (2 min)  | Scale up (+1 instance)    |
| cpu-low                   | CPU < 30% (2 min)  | Scale down (-1 instance)  |
| unhealthy-hosts           | Unhealthy > 0      | Notification              |
| rds-cpu-high              | RDS CPU > 80%      | Notification              |

### Créer une alarme personnalisée

```bash
# Exemple : Alarme sur trop de requêtes 5xx
aws cloudwatch put-metric-alarm \
  --alarm-name student-records-high-5xx \
  --alarm-description "Too many 5xx errors" \
  --metric-name HTTPCode_Target_5XX_Count \
  --namespace AWS/ApplicationELB \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

## Troubleshooting

### Problème : Instances unhealthy

**Symptômes :**
```
Target health checks failing
```

**Solution :**
```bash
# Vérifier les logs d'une instance
INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names student-records-asg-phase6 \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
  --output text)

# SSH vers l'instance
aws ec2-instance-connect ssh --instance-id $INSTANCE_ID

# Vérifier les logs Docker
sudo docker logs student-records-app

# Vérifier le health check
curl http://localhost/students
```

### Problème : Scaling ne fonctionne pas

**Vérifications :**
```bash
# 1. Vérifier les alarmes CloudWatch
aws cloudwatch describe-alarms \
  --alarm-name-prefix student-records \
  --state-value ALARM

# 2. Vérifier les métriques ASG
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=student-records-asg-phase6 \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average

# 3. Vérifier l'historique de scaling
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name student-records-asg-phase6 \
  --max-records 10
```

### Problème : RDS Multi-AZ failover

**Tester le failover :**
```bash
# Forcer un reboot avec failover
aws rds reboot-db-instance \
  --db-instance-identifier student-records-phase6 \
  --force-failover

# Observer le changement d'endpoint
watch -n 5 'aws rds describe-db-instances \
  --db-instance-identifier student-records-phase6 \
  --query "DBInstances[0].[DBInstanceStatus,AvailabilityZone]"'
```

**Résultat attendu :** Failover complet en 1-2 minutes

### Problème : Image Docker introuvable

**Solution :**
```bash
# 1. Créer le repo ECR (sera fait par Terraform)
terraform apply -target=aws_ecr_repository.student_records_app

# 2. Build et push l'image
cd ../../phase4
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $(terraform -chdir=../phase6/terraform output -raw ecr_repository_url | cut -d/ -f1)

docker build -t student-records-app .
docker tag student-records-app:latest \
  $(terraform -chdir=../phase6/terraform output -raw ecr_repository_url):latest
docker push $(terraform -chdir=../phase6/terraform output -raw ecr_repository_url):latest

# 3. Forcer le refresh des instances
cd ../phase6/terraform
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name student-records-asg-phase6
```

## Learnings

### Ce qui fonctionne bien

1. **Multi-AZ RDS** : Failover transparent en ~90 secondes
2. **Target Tracking** : Meilleur que simple scaling pour maintenir performance stable
3. **ALB Health Checks** : Détection rapide des instances défaillantes
4. **Auto Healing** : Remplacement automatique sans intervention manuelle
5. **CloudWatch Dashboard** : Vue complète de l'infrastructure en temps réel

### Points d'attention

1. **Coût** : Multi-AZ RDS = 2x le coût d'une instance single-AZ
2. **Warmup Time** : Nouvelles instances prennent ~3 minutes à être prêtes
3. **Database Init** : Chaque instance initialise la DB (idempotent mais répétitif)
4. **Session Persistence** : Pas de sticky sessions (OK pour API stateless)
5. **Scaling Delay** : 2 minutes d'évaluation + 5 minutes de cooldown

### Améliorations possibles

- **ElastiCache** : Ajouter Redis pour les sessions et cache
- **CloudFront** : CDN pour les assets statiques
- **SSL/TLS** : Certificate Manager + HTTPS sur ALB
- **Blue/Green** : Déploiements sans downtime via ASG
- **Scheduled Scaling** : Prévoir les pics de charge (ex: 9h-17h)
- **Custom Metrics** : Métriques applicatives dans CloudWatch
- **SNS Notifications** : Alertes par email/SMS sur alarmes

## Nettoyage

Pour détruire toute l'infrastructure :

```bash
cd /home/nicog/aws/student-records-app-capstone/phase6/terraform

# Destroy complet
terraform destroy -auto-approve
```

**Durée :** ~10 minutes (RDS prend du temps)

## Résumé des commandes

```bash
# Déploiement
terraform init
terraform apply -auto-approve

# Monitoring
terraform output application_url
terraform output cloudwatch_dashboard_url
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names student-records-asg-phase6

# Load testing
ab -n 1000 -c 50 $(terraform output -raw application_url)/students

# Scaling manuel (test)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name student-records-asg-phase6 \
  --desired-capacity 4

# Cleanup
terraform destroy -auto-approve
```

## Validation

Pour valider cette phase :

1. ALB accessible et distribue le trafic
2. Au moins 2 instances running dans différentes AZ
3. RDS Multi-AZ activé (standby replica)
4. Health checks passent (target group healthy)
5. Auto-scaling fonctionne (scale up/down sur charge CPU)
6. Dashboard CloudWatch affiche les métriques
7. Application répond sur ALB DNS
8. Failover RDS fonctionne (test optionnel)

---

## Vidéos de démonstration

Les vidéos de déploiement et de test sont disponibles sur **MyDrive** :
[https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing](https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing)

**Phase 6 complète** : High Availability & Auto-Scaling 

**Architecture :** Multi-AZ, Auto-scaling, Monitoring complet
**Capacité :** 2-4 instances, RDS Multi-AZ, ALB multi-zones
**Résultat :** Infrastructure production-ready avec 99.9% disponibilité
