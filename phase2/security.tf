# Groupe de securite pour les serveurs web
resource "aws_security_group" "web_server" {
  name        = "${var.project_name}-web-sg"
  description = "Groupe de securite pour le serveur web - Phase 2"
  vpc_id      = aws_vpc.main.id

  # Acces HTTP depuis n'importe ou
  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Acces SSH pour l'administration
  ingress {
    description = "Acces SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Sortant - Tout autoriser
  egress {
    description = "Autoriser tout le trafic sortant"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-web-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Groupe de securite pour RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Groupe de securite pour RDS MySQL - Phase 2"
  vpc_id      = aws_vpc.main.id

  # Acces MySQL depuis le serveur web uniquement
  ingress {
    description     = "MySQL depuis serveur web"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server.id]
  }

  # Acces MySQL depuis Cloud9 pour migration
  ingress {
    description     = "MySQL depuis Cloud9"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.cloud9.id]
  }

  # Sortant - Tout autoriser
  egress {
    description = "Autoriser tout le trafic sortant"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Groupe de securite pour Cloud9
resource "aws_security_group" "cloud9" {
  name        = "${var.project_name}-cloud9-sg"
  description = "Groupe de securite pour Cloud9 - Phase 2"
  vpc_id      = aws_vpc.main.id

  # Sortant - Tout autoriser
  egress {
    description = "Autoriser tout le trafic sortant"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-cloud9-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}
