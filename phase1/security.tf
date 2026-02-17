# Groupe de securite pour le serveur web
resource "aws_security_group" "web_server" {
  name        = "${var.project_name}-web-sg"
  description = "Groupe de securite pour le serveur web - Phase 1"
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

  # Acces MySQL (pour Phase 1 - sur la meme instance)
  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
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
