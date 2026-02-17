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
  default     = "phase1"
}

variable "vpc_cidr" {
  description = "Bloc CIDR pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Bloc CIDR pour le sous-réseau public"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Zone de disponibilité pour les ressources"
  type        = string
  default     = "us-east-1a"
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
