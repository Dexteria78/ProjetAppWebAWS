output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.application.dns_name
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.application.dns_name}"
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.student_records_app.repository_url
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_multi_az" {
  description = "Whether the RDS instance is Multi-AZ"
  value       = aws_db_instance.mysql.multi_az
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web_servers.name
}

output "autoscaling_group_size" {
  description = "Current size configuration of Auto Scaling Group"
  value = {
    min     = var.asg_min_size
    max     = var.asg_max_size
    desired = var.asg_desired_capacity
  }
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "db_secret_name" {
  description = "Name of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.application.arn
}

output "load_test_command" {
  description = "Command to run load test against the application"
  value       = "ab -n 1000 -c 50 http://${aws_lb.application.dns_name}/students"
}
