variable "aws_region" {
  description = "AWS region pour deployer les ressources"
  type        = string
  default     = "us-east-1"
}

variable "db_username" {
  description = "Username pour la base de donnees MySQL"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Password pour la base de donnees MySQL"
  type        = string
  sensitive   = true
  default     = "Admin123456!"
}

variable "instance_type" {
  description = "Type d'instance EC2 pour le Docker host"
  type        = string
  default     = "t3.small"
}
