# Phase 5 : Mise en Place d'une Pipeline CI/CD

## Objectif

Automatiser le déploiement de l'application avec une pipeline CI/CD complète.

## Exigences Phase 5

- Configurer un **GitLab CI/CD**, **GitHub Actions** ou **AWS CodePipeline**
- Définir les étapes suivantes :
  - **Build** de l'application
  - **Test de qualité** (linting, tests unitaires)
  - **Packaging et push de l'image Docker**
  - **Test de charge**
  - **Déploiement sur l'environnement de production**

---

## Vue d'ensemble Détaillée

Cette phase implémente un pipeline CI/CD complet avec **GitHub Actions** pour automatiser le build, les tests, le packaging et le déploiement de l'application Student Records.

## Architecture du Pipeline

```

   PUSH      
  (main)     

       
       

                    STAGE 1: BUILD                       
  • Checkout code                                        
  • Setup Node.js 18                                     
  • Install dependencies (npm ci)                        
  • Upload artifacts                                     

                       
                       

                    STAGE 2: TEST                        
  • Download build artifacts                             
  • Run ESLint                                           
  • Run unit tests                                       
  • Code quality checks                                  

                       
                       

                  STAGE 3: PACKAGE                       
  • Build Docker image (multi-stage)                     
  • Scan for vulnerabilities (Trivy)                     
  • Tag: <commit-sha> + latest                           
  • Push to Amazon ECR                                   

                       
                       

                 STAGE 4: LOAD TEST                      
  • Start app with docker-compose                        
  • Run Apache Bench load tests                          
  • Validate response times                              
  • Performance metrics                                  

                       
                       

                   STAGE 5: DEPLOY                       
  • Configure AWS credentials                            
  • Terraform init/plan/apply                            
  • Deploy to EC2 + RDS                                  
  • Verify deployment                                    

```

## Fonctionnalités

### Pipeline Automatisé
- **Build** : Installation et compilation de l'application
- **Test** : Linting, tests unitaires, qualité du code
- **Package** : Build Docker + scan de sécurité
- **Load Test** : Tests de performance avec Apache Bench
- **Deploy** : Déploiement automatique sur AWS via Terraform

### Déclencheurs
- Push sur `main` : Pipeline complet (build → test → package → load test → deploy)
- Push sur `develop` : Build et tests uniquement
- Pull Request vers `main` : Build et tests
- Déclenchement manuel : Via `workflow_dispatch`

### Sécurité
- Scan de vulnérabilités avec **Trivy**
- Credentials AWS stockés dans GitHub Secrets
- Session tokens pour AWS Academy
- Multi-stage build pour minimiser l'image

## Configuration requise

### GitHub Secrets à configurer

Allez dans **Settings → Secrets and variables → Actions** et ajoutez :

```
AWS_ACCESS_KEY_ID        = <votre access key>
AWS_SECRET_ACCESS_KEY    = <votre secret key>
AWS_SESSION_TOKEN        = <votre session token>  # Pour AWS Academy
```

### Prérequis AWS
- Compte AWS Academy avec permissions :
  - ECR (push/pull images)
  - EC2 (lancement instances)
  - RDS (création base de données)
  - Secrets Manager
  - VPC/Security Groups
- ECR Repository créé : `student-records-app`

## Utilisation

### 1. Configuration initiale

```bash
# Cloner le repo
git clone https://github.com/Dexteria78/ProjetAppWebAWS.git
cd ProjetAppWebAWS

# Vérifier la structure
ls -la phase5/.github/workflows/
```

### 2. Configurer les secrets GitHub

```bash
# Dans GitHub : Settings → Secrets → New repository secret
# Ajouter AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN
```

### 3. Déclencher le pipeline

#### Option A : Push sur main
```bash
git checkout main
git add .
git commit -m "feat: deploy application"
git push origin main
```

#### Option B : Déclenchement manuel
1. Aller sur GitHub → Actions
2. Sélectionner "CI/CD Pipeline - Student Records App"
3. Cliquer "Run workflow"

### 4. Suivre l'exécution

```
GitHub → Actions → Workflow run
```

Vous verrez les 5 stages s'exécuter séquentiellement :
1. Build Application
2. Run Tests
3. Build and Push Docker Image
4. Performance Load Test
5. Deploy to AWS

## Résultats attendus

### Build (Stage 1)
```
 Dependencies installed: 122 packages
 Build artifacts uploaded
Duration: ~30s
```

### Test (Stage 2)
```
 ESLint completed
 Unit tests passed (or skipped if none)
 Code quality checks passed
Duration: ~20s
```

### Package (Stage 3)
```
 Docker image built: 134MB
 Security scan completed
 Pushed to ECR:
  - student-records-app:<commit-sha>
  - student-records-app:latest
Duration: ~2min
```

### Load Test (Stage 4)
```
Test 1: GET /students
  Requests: 100
  Concurrency: 10
  
Test 2: Homepage
  Requests: 200
  Concurrency: 20
  
 Response time < 1s
Duration: ~45s
```

### Deploy (Stage 5)
```
 Terraform applied
 Infrastructure deployed:
  - EC2 t3.small
  - RDS MySQL 8.0
  - Security groups
  - Secrets Manager
 Application URL: http://<public-ip>
Duration: ~8min
```

## Personnalisation

### Modifier les tests de charge

Éditez `.github/workflows/ci-cd.yml` section `load-test` :

```yaml
- name: Run basic load test
  run: |
    # Augmenter les requêtes
    ab -n 500 -c 50 http://localhost:3000/students
```

### Ajouter des tests unitaires

Créez `resources/codebase_partner/test/` :

```javascript
// test/app.test.js
const request = require('supertest');
const app = require('../app');

describe('GET /students', () => {
  it('should return student list', async () => {
    const res = await request(app).get('/students');
    expect(res.statusCode).toBe(200);
  });
});
```

### Déployer sur un environnement de staging

Ajoutez un job intermédiaire :

```yaml
deploy-staging:
  name: Deploy to Staging
  runs-on: ubuntu-latest
  needs: load-test
  environment: staging
  steps:
    - name: Deploy to staging EC2
      run: |
        # Commandes de déploiement staging
```

## Métriques et Monitoring

### Temps d'exécution typique

| Stage     | Durée      | Action principale          |
|-----------|------------|----------------------------|
| Build     | ~30s       | npm ci                     |
| Test      | ~20s       | ESLint + tests             |
| Package   | ~2min      | Docker build + push ECR    |
| Load Test | ~45s       | Apache Bench               |
| Deploy    | ~8min      | Terraform apply            |
| **TOTAL** | **~11min** | Pipeline complet           |

### Indicateurs de succès

- **Build rate** : 100% (si dépendances OK)
- **Test coverage** : À améliorer (actuellement 0%)
- **Security** : Aucune vulnérabilité critique
- **Performance** : < 1s response time
- **Deploy success** : Infrastructure créée automatiquement

## Troubleshooting

### Erreur : "ECR Repository not found"

**Solution** : Créer le repo ECR manuellement
```bash
aws ecr create-repository --repository-name student-records-app --region us-east-1
```

### Erreur : "AWS credentials not configured"

**Solution** : Vérifier les GitHub Secrets
```
Settings → Secrets → AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN
```

### Erreur : "Terraform state locked"

**Solution** : Attendre ou forcer le déverrouillage
```bash
terraform force-unlock <lock-id>
```

### Load tests échouent

**Solution** : Augmenter le temps d'attente
```yaml
- name: Wait for application to be ready
  run: |
    sleep 30  # Augmenter de 15s à 30s
```

### Déploiement lent (> 10min)

**Cause** : RDS prend 6-7 minutes à démarrer  
**Solution** : Normal pour une base de données gérée

## Learnings

### Ce qui fonctionne bien
- **Pipeline modulaire** : Chaque stage isolé
- **Artifacts** : Partage de build entre stages
- **Scan sécurité** : Trivy détecte les CVEs
- **Load tests** : Apache Bench simple et efficace
- **Terraform** : Infrastructure as Code = déploiement reproductible

### Limitations AWS Academy
- Session tokens expirent après 3 heures
- Pas de S3 pour le backend Terraform (state local)
- Quotas limités (max 2 EC2 instances)
- Certaines ressources persistent après la session

### Améliorations possibles
- **Tests unitaires** : Ajouter Jest + couverture à 80%
- **Blue/Green deployment** : Zéro downtime
- **Notifications** : Slack/Discord sur succès/échec
- **Rollback** : Auto-rollback si deploy échoue
- **Monitoring** : CloudWatch + alertes

## Ressources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECR User Guide](https://docs.aws.amazon.com/ecr/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Apache Bench Guide](https://httpd.apache.org/docs/2.4/programs/ab.html)
- [Trivy Security Scanner](https://github.com/aquasecurity/trivy)

## Validation

Pour valider cette phase :

1. Le pipeline s'exécute automatiquement sur push
2. Les 5 stages passent au vert
3. L'image Docker est dans ECR
4. Les load tests montrent < 1s response time
5. L'application est déployée et accessible via URL

---

## Vidéos de démonstration

Les vidéos de déploiement et de test sont disponibles sur **MyDrive** :
[https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing](https://drive.google.com/drive/folders/1698wO-jPW8hJ28d3EpMSmLd9UDllHKDm?usp=sharing)

**Phase 5 complète** : Pipeline CI/CD avec GitHub Actions 

<- Cloud9 environment for database Pipeline CI/CD activé le 2026-02-18 14:19:37 -->

<- Cloud9 environment for database Infrastructure cleaned - ready for deployment 2026-02-18 15:58:22 -->

<- Cloud9 environment for database ECR repository deleted - rerun 2026-02-18 16:10:28 -->
