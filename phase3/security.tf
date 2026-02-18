# ==============================================================================
# Security Group pour Application Load Balancer - Phase 3
# ==============================================================================
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer - Phase 3"
  vpc_id      = aws_vpc.main.id

  # Acces HTTP depuis Internet
  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ==============================================================================
# Security Group pour les serveurs web (instances ASG) - Phase 3
# ==============================================================================
resource "aws_security_group" "web_server" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers - Phase 3"
  vpc_id      = aws_vpc.main.id

  # Acces HTTP depuis le Load Balancer uniquement
  ingress {
    description     = "HTTP depuis ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
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

# ==============================================================================
# Security Group pour RDS MySQL - Phase 3
# ==============================================================================
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS MySQL - Phase 3"
  vpc_id      = aws_vpc.main.id

  # Acces MySQL depuis le serveur web uniquement
  ingress {
    description     = "MySQL depuis serveurs web (ASG)"
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

# ==============================================================================
# Security Group pour Cloud9 - Phase 3
# ==============================================================================
resource "aws_security_group" "cloud9" {
  name        = "${var.project_name}-cloud9-sg"
  description = "Security group for Cloud9 - Phase 3"
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
