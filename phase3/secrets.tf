# Secret dans AWS Secrets Manager pour stocker les credentials de la base de données
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}-db-credentials-${var.environment}"
  description = "Credentials pour la base de données RDS MySQL"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Version du secret avec les credentials
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "mysql"
    host     = aws_db_instance.main.address
    port     = 3306
    dbname   = var.db_name
  })
}
