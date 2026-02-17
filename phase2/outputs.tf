output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID du sous-réseau public"
  value       = aws_subnet.public.id
}

output "private_subnet_1_id" {
  description = "ID du premier sous-réseau privé"
  value       = aws_subnet.private_1.id
}

output "private_subnet_2_id" {
  description = "ID du deuxième sous-réseau privé"
  value       = aws_subnet.private_2.id
}

output "web_server_id" {
  description = "ID de l'instance serveur web"
  value       = aws_instance.web_server.id
}

output "web_server_public_ip" {
  description = "IP publique du serveur web"
  value       = aws_instance.web_server.public_ip
}

output "web_server_public_dns" {
  description = "DNS public du serveur web"
  value       = aws_instance.web_server.public_dns
}

output "application_url" {
  description = "URL de l'application"
  value       = "http://${aws_instance.web_server.public_ip}"
}

output "rds_endpoint" {
  description = "Endpoint de la base de données RDS"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "Adresse de la base de données RDS"
  value       = aws_db_instance.main.address
}

output "secrets_manager_arn" {
  description = "ARN du secret dans Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secrets_manager_name" {
  description = "Nom du secret dans Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "cloud9_environment_id" {
  description = "ID de l'environnement Cloud9"
  value       = aws_cloud9_environment_ec2.migration.id
}

output "cloud9_url" {
  description = "URL de l'environnement Cloud9"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.migration.id}"
}

output "ssh_command" {
  description = "Commande SSH pour se connecter au serveur web"
  value       = "ssh -i <your-key.pem> ubuntu@${aws_instance.web_server.public_ip}"
}
