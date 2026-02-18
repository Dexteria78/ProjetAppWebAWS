variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "student-records-app"
}

variable "db_identifier" {
  description = "Identifier for the RDS database"
  type        = string
  default     = "student-records"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "studentrecordsdb"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
}

variable "db_instance_class" {
  description = "Instance class for RDS database"
  type        = string
  default     = "db.t3.micro"
}

variable "instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.small"
}

variable "asg_min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}
