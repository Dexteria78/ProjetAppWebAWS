# ==============================================================================
# Outputs - Phase 3
# ==============================================================================

# VPC
output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

# Subnets publics
output "public_subnet_1_id" {
  description = "ID du premier sous-réseau public"
  value       = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  description = "ID du deuxième sous-réseau public"
  value       = aws_subnet.public_2.id
}

# Subnets privés
output "private_subnet_1_id" {
  description = "ID du premier sous-réseau privé"
  value       = aws_subnet.private_1.id
}

output "private_subnet_2_id" {
  description = "ID du deuxième sous-réseau privé"
  value       = aws_subnet.private_2.id
}

# Application Load Balancer
output "alb_dns_name" {
  description = "DNS name du Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN du Load Balancer"
  value       = aws_lb.main.arn
}

output "application_url" {
  description = "URL de l'application (via Load Balancer)"
  value       = "http://${aws_lb.main.dns_name}"
}

# Auto Scaling Group
output "autoscaling_group_name" {
  description = "Nom de l'Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "autoscaling_group_arn" {
  description = "ARN de l'Auto Scaling Group"
  value       = aws_autoscaling_group.web.arn
}

# Target Group
output "target_group_arn" {
  description = "ARN du Target Group"
  value       = aws_lb_target_group.web.arn
}

# RDS
output "rds_endpoint" {
  description = "Endpoint de la base de données RDS"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "Adresse de la base de données RDS"
  value       = aws_db_instance.main.address
}

# Secrets Manager
output "secrets_manager_arn" {
  description = "ARN du secret dans Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secrets_manager_name" {
  description = "Nom du secret dans Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.name
}

# Cloud9
output "cloud9_environment_id" {
  description = "ID de l'environnement Cloud9"
  value       = aws_cloud9_environment_ec2.migration.id
}

output "cloud9_url" {
  description = "URL de l'environnement Cloud9"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.migration.id}"
}
