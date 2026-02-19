# Phase 4 - Infrastructure Terraform pour ECR et EC2
# Provider AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
  
  # Backend S3 pour partager le state entre GitHub Actions et local
  backend "s3" {
    bucket = "student-records-terraform-state-1771428261"
    key    = "phase4/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source pour obtenir l'account ID
data "aws_caller_identity" "current" {}

# Data source pour obtenir le VPC par défaut
data "aws_vpc" "default" {
  default = true
}

# Data source pour obtenir les subnets du VPC par défaut
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ECR Repository pour stocker l'image Docker
resource "aws_ecr_repository" "student_records_app" {
  name                 = "student-records-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "student-records-app-ecr"
    Project     = "StudentRecords"
    Phase       = "4"
    Environment = "production"
  }

  lifecycle {
    create_before_destroy = false
    prevent_destroy       = false
  }
}

# Lifecycle policy pour ECR (garder seulement les 10 dernières images)
resource "aws_ecr_lifecycle_policy" "student_records_app" {
  repository = aws_ecr_repository.student_records_app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Null resource pour build et push l'image Docker automatiquement
resource "null_resource" "docker_build_push" {
  depends_on = [aws_ecr_repository.student_records_app]

  triggers = {
    # Reconstruire si les fichiers de l'application changent
    docker_file = filemd5("${path.module}/../Dockerfile")
    package_json = filemd5("${path.module}/../resources/codebase_partner/package.json")
    # Force rebuild à chaque apply pour s'assurer que l'image est à jour
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Building and pushing Docker image to ECR..."
      
      # Se connecter à ECR
      aws ecr get-login-password --region ${var.aws_region} | \
        docker login --username AWS --password-stdin ${aws_ecr_repository.student_records_app.repository_url}
      
      # Build l'image
      cd ${path.module}/..
      docker build -t student-records-app:latest .
      
      # Tag l'image
      docker tag student-records-app:latest ${aws_ecr_repository.student_records_app.repository_url}:latest
      
      # Push vers ECR
      docker push ${aws_ecr_repository.student_records_app.repository_url}:latest
      
      echo "Docker image pushed successfully!"
    EOT
  }
}

# Security Group pour l'instance EC2
resource "aws_security_group" "docker_instance" {
  name        = "student-records-docker-instance-sg"
  description = "Security group for Docker instance running student records app"
  vpc_id      = data.aws_vpc.default.id

  lifecycle {
    create_before_destroy = false
  }

  # SSH
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP pour l'application
  ingress {
    description = "HTTP for application"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress - tout sortant
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "student-records-docker-instance-sg"
    Project = "StudentRecords"
    Phase   = "4"
  }
}

# Security Group pour RDS MySQL
resource "aws_security_group" "rds_mysql" {
  name        = "student-records-rds-mysql-sg-phase4"
  description = "Security group for RDS MySQL database"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "MySQL from Docker instance"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.docker_instance.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "student-records-rds-mysql-sg-phase4"
    Project = "StudentRecords"
    Phase   = "4"
  }
}

# DB Subnet Group pour RDS
resource "aws_db_subnet_group" "mysql" {
  name       = "student-records-db-subnet-group-phase4"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name    = "student-records-db-subnet-group-phase4"
    Project = "StudentRecords"
    Phase   = "4"
  }
}

# RDS MySQL Database
resource "aws_db_instance" "mysql" {
  identifier     = "student-records-db-phase4"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "STUDENTS"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  vpc_security_group_ids = [aws_security_group.rds_mysql.id]

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  skip_final_snapshot       = true
  final_snapshot_identifier = null

  publicly_accessible = false
  multi_az            = false

  tags = {
    Name    = "student-records-db-phase4"
    Project = "StudentRecords"
    Phase   = "4"
  }
}

# Secrets Manager pour stocker les credentials de la DB
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "student-records-app-db-credentials-phase4"
  description             = "Database credentials for Student Records Application Phase 4"
  recovery_window_in_days = 0

  tags = {
    Name    = "student-records-app-db-credentials-phase4"
    Project = "StudentRecords"
    Phase   = "4"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.mysql.address
    port     = aws_db_instance.mysql.port
    dbname   = aws_db_instance.mysql.db_name
  })
}

# IAM Instance Profile pour EC2 - utilise le LabRole existant dans AWS Academy
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

data "aws_iam_instance_profile" "lab_instance_profile" {
  name = "LabInstanceProfile"
}

# Data source pour obtenir la dernière AMI Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance avec Docker
resource "aws_instance" "docker_host" {
  depends_on = [
    aws_db_instance.mysql,
    aws_secretsmanager_secret_version.db_credentials,
    null_resource.docker_build_push
  ]

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.docker_instance.id]
  iam_instance_profile   = data.aws_iam_instance_profile.lab_instance_profile.name

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    ecr_repository_url = aws_ecr_repository.student_records_app.repository_url
    aws_region         = var.aws_region
    db_secret_name     = aws_secretsmanager_secret.db_credentials.name
  }))

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name    = "student-records-docker-host"
    Project = "StudentRecords"
    Phase   = "4"
  }
}
