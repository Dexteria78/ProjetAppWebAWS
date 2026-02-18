variable "aws_region" {
  description = "Région AWS pour le déploiement"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nom du projet pour le tagging des ressources"
  type        = string
  default     = "student-records-app"
}

variable "environment" {
  description = "Nom de l'environnement"
  type        = string
  default     = "phase3"
}

variable "vpc_cidr" {
  description = "Bloc CIDR pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "Bloc CIDR pour le premier sous-réseau public"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "Bloc CIDR pour le deuxième sous-réseau public"
  type        = string
  default     = "10.0.4.0/24"
}

variable "private_subnet_1_cidr" {
  description = "Bloc CIDR pour le premier sous-réseau privé (RDS)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_2_cidr" {
  description = "Bloc CIDR pour le deuxième sous-réseau privé (RDS)"
  type        = string
  default     = "10.0.3.0/24"
}

variable "availability_zone_1" {
  description = "Première zone de disponibilité"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "Deuxième zone de disponibilité"
  type        = string
  default     = "us-east-1b"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}

variable "allowed_ssh_cidr" {
  description = "Bloc CIDR autorisé pour l'accès SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "STUDENTS"
}

variable "db_username" {
  description = "Nom d'utilisateur de la base de données"
  type        = string
  default     = "admin"
}

variable "db_instance_class" {
  description = "Classe d'instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Stockage alloué pour RDS (GB)"
  type        = number
  default     = 20
}

variable "volume_size" {
  description = "Taille du volume EBS pour les instances EC2 (GB)"
  type        = number
  default     = 20
}
