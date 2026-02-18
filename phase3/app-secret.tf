# Secret spécifique pour l'application (nom et structure attendus par le code)
resource "aws_secretsmanager_secret" "app_db_credentials" {
  name        = "Mydbsecret"
  description = "Credentials de base de données pour l'application Node.js"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Version du secret avec la structure attendue par l'application
resource "aws_secretsmanager_secret_version" "app_db_credentials" {
  secret_id = aws_secretsmanager_secret.app_db_credentials.id
  secret_string = jsonencode({
    user     = var.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.main.address
    db       = var.db_name
  })
}
