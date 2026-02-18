output "ecr_repository_url" {
  description = "URL du repository ECR"
  value       = aws_ecr_repository.student_records_app.repository_url
}

output "ecr_repository_arn" {
  description = "ARN du repository ECR"
  value       = aws_ecr_repository.student_records_app.arn
}

output "docker_instance_public_ip" {
  description = "Adresse IP publique de l'instance Docker"
  value       = aws_instance.docker_host.public_ip
}

output "docker_instance_id" {
  description = "ID de l'instance Docker"
  value       = aws_instance.docker_host.id
}

output "rds_endpoint" {
  description = "Endpoint de la base de donnees RDS MySQL"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_address" {
  description = "Adresse de la base de donnees RDS MySQL"
  value       = aws_db_instance.mysql.address
}

output "db_secret_arn" {
  description = "ARN du secret contenant les credentials de la DB"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "application_url" {
  description = "URL pour acceder a l'application"
  value       = "http://${aws_instance.docker_host.public_ip}"
}

output "ecr_login_command" {
  description = "Commande pour se connecter a ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "docker_push_commands" {
  description = "Commandes pour pousser l'image vers ECR"
  value = <<-EOT
    # Tag the image
    docker tag student-records-app:latest ${aws_ecr_repository.student_records_app.repository_url}:latest
    
    # Push to ECR
    docker push ${aws_ecr_repository.student_records_app.repository_url}:latest
  EOT
}
