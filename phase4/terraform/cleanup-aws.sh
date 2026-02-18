#!/bin/bash
echo "🧹 Nettoyage complet des ressources AWS orphelines"
echo "=================================================="

# Secret Manager
aws secretsmanager delete-secret --secret-id student-records-app-db-credentials-phase4 --force-delete-without-recovery 2>/dev/null && echo "✅ Secret supprimé" || echo "ℹ️  Secret n'existe pas"

# DB Subnet Group
aws rds delete-db-subnet-group --db-subnet-group-name student-records-db-subnet-group-phase4 2>/dev/null && echo "✅ DB Subnet Group supprimé" || echo "ℹ️  DB Subnet Group n'existe pas"

# ECR
aws ecr delete-repository --repository-name student-records-app --force 2>/dev/null && echo "✅ ECR supprimé" || echo "ℹ️  ECR n'existe pas"

# Security Groups - avec retry
echo "Suppression des Security Groups..."
sleep 2
for SG in sg-041516a977b91f4bb sg-077a31c720db51530; do
  aws ec2 delete-security-group --group-id "$SG" 2>/dev/null && echo "✅ SG $SG supprimé" || echo "⏭️  SG $SG non trouvé ou bloqué"
done

echo ""
echo "✅ Nettoyage terminé! Maintenant terraform apply créera tout proprement."
