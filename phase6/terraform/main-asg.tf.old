terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend S3 pour partager le state (Phase 6 séparé de Phase 4/5)
  backend "s3" {
    bucket = "student-records-terraform-state-1771428261"
    key    = "phase6/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

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

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

data "aws_iam_instance_profile" "lab_instance_profile" {
  name = "LabInstanceProfile"
}

# ===================================
# ECR Repository (réutilisé de Phase 4)
# ===================================
resource "aws_ecr_repository" "student_records_app" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = var.ecr_repository_name
    Phase   = "6"
    Project = "StudentRecords"
  }
}

resource "aws_ecr_lifecycle_policy" "student_records_app" {
  repository = aws_ecr_repository.student_records_app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ===================================
# RDS MySQL Database (Multi-AZ)
# ===================================
resource "aws_db_subnet_group" "mysql" {
  name       = "${var.db_identifier}-subnet-group-phase6"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name    = "${var.db_identifier}-subnet-group-phase6"
    Phase   = "6"
    Project = "StudentRecords"
  }
}

resource "aws_security_group" "rds_mysql" {
  name        = "${var.db_identifier}-rds-mysql-sg-phase6"
  description = "Security group for RDS MySQL database"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "MySQL from ALB instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_instances.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.db_identifier}-rds-mysql-sg-phase6"
    Phase   = "6"
    Project = "StudentRecords"
  }
}

resource "aws_db_instance" "mysql" {
  identifier                = "${var.db_identifier}-phase6"
  engine                    = "mysql"
  engine_version            = "8.0.35"
  instance_class            = var.db_instance_class
  allocated_storage         = 20
  storage_type              = "gp3"
  storage_encrypted         = true
  
  # Multi-AZ for high availability
  multi_az                  = true
  
  db_name                   = var.db_name
  username                  = var.db_username
  password                  = random_password.db_password.result
  
  db_subnet_group_name      = aws_db_subnet_group.mysql.name
  vpc_security_group_ids    = [aws_security_group.rds_mysql.id]
  
  backup_retention_period   = 7
  backup_window             = "03:00-04:00"
  maintenance_window        = "mon:04:00-mon:05:00"
  
  skip_final_snapshot       = true
  deletion_protection       = false
  
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name    = "${var.db_identifier}-phase6"
    Phase   = "6"
    Project = "StudentRecords"
  }
}

# ===================================
# Secrets Manager
# ===================================
resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name_prefix             = "${var.db_identifier}-db-credentials-phase6-"
  recovery_window_in_days = 0

  tags = {
    Name    = "${var.db_identifier}-db-credentials-phase6"
    Phase   = "6"
    Project = "StudentRecords"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.mysql.address
    port     = aws_db_instance.mysql.port
    dbname   = var.db_name
  })
}

# Also create the "Mydbsecret" for app compatibility
resource "aws_secretsmanager_secret" "app_db_secret" {
  name                    = "Mydbsecret"
  recovery_window_in_days = 0

  tags = {
    Name    = "Mydbsecret"
    Phase   = "6"
    Project = "StudentRecords"
  }
}

resource "aws_secretsmanager_secret_version" "app_db_secret" {
  secret_id = aws_secretsmanager_secret.app_db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.mysql.address
    port     = aws_db_instance.mysql.port
    dbname   = var.db_name
  })
}

# ===================================
# Application Load Balancer
# ===================================
resource "aws_security_group" "alb" {
  name        = "student-records-alb-sg-phase6"
  description = "Security group for Application Load Balancer"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "student-records-alb-sg-phase6"
    Phase   = "6"
    Project = "StudentRecords"
  }
}

resource "aws_lb" "application" {
  name               = "student-records-alb-phase6"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false
  enable_http2              = true

  tags = {
    Name    = "student-records-alb-phase6"
    Phase   = "6"
    Project = "StudentRecords"
  }
}

resource "aws_lb_target_group" "application" {
  name     = "student-records-tg-phase6"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/students"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name    = "student-records-tg-phase6"
    Phase   = "6"
    Project = "StudentRecords"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }
}

# ===================================
# Launch Template
# ===================================
resource "aws_security_group" "web_instances" {
  name        = "student-records-web-instances-sg-phase6"
  description = "Security group for web server instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "student-records-web-instances-sg-phase6"
    Phase   = "6"
    Project = "StudentRecords"
  }
}

resource "aws_launch_template" "web_server" {
  name_prefix   = "student-records-lt-phase6-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = data.aws_iam_instance_profile.lab_instance_profile.arn
  }

  vpc_security_group_ids = [aws_security_group.web_instances.id]

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    aws_region          = var.aws_region
    ecr_repository_uri  = aws_ecr_repository.student_records_app.repository_url
    db_secret_name      = aws_secretsmanager_secret.db_credentials.name
    db_name             = var.db_name
    db_host             = aws_db_instance.mysql.address
  }))

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "student-records-web-instance-phase6"
      Phase   = "6"
      Project = "StudentRecords"
    }
  }

  tags = {
    Name    = "student-records-launch-template-phase6"
    Phase   = "6"
    Project = "StudentRecords"
  }
}

# ===================================
# Auto Scaling Group
# ===================================
resource "aws_autoscaling_group" "web_servers" {
  name                = "student-records-asg-phase6"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.application.arn]
  
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity
  
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web_server.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupTotalInstances"
  ]

  tag {
    key                 = "Name"
    value               = "student-records-asg-instance-phase6"
    propagate_at_launch = true
  }

  tag {
    key                 = "Phase"
    value               = "6"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "StudentRecords"
    propagate_at_launch = true
  }
}

# ===================================
# Auto Scaling Policies
# ===================================

# Scale UP policy (CPU > 70%)
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "student-records-scale-up-phase6"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_servers.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "student-records-cpu-high-phase6"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "Scale up when CPU exceeds 70%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_servers.name
  }
}

# Scale DOWN policy (CPU < 30%)
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "student-records-scale-down-phase6"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_servers.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "student-records-cpu-low-phase6"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "Scale down when CPU below 30%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_servers.name
  }
}

# Target tracking scaling policy (maintain 50% CPU)
resource "aws_autoscaling_policy" "target_tracking" {
  name                   = "student-records-target-tracking-phase6"
  autoscaling_group_name = aws_autoscaling_group.web_servers.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

# ===================================
# CloudWatch Dashboard
# ===================================
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "student-records-dashboard-phase6"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average" }],
            [".", "RequestCount", { stat = "Sum" }],
            [".", "HTTPCode_Target_2XX_Count", { stat = "Sum" }],
            [".", "HTTPCode_Target_5XX_Count", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", dimensions = { AutoScalingGroupName = aws_autoscaling_group.web_servers.name } }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Auto Scaling Group CPU"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", { dimensions = { AutoScalingGroupName = aws_autoscaling_group.web_servers.name } }],
            [".", "GroupInServiceInstances", { dimensions = { AutoScalingGroupName = aws_autoscaling_group.web_servers.name } }],
            [".", "GroupMinSize", { dimensions = { AutoScalingGroupName = aws_autoscaling_group.web_servers.name } }],
            [".", "GroupMaxSize", { dimensions = { AutoScalingGroupName = aws_autoscaling_group.web_servers.name } }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Auto Scaling Group Instances"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", { dimensions = { DBInstanceIdentifier = aws_db_instance.mysql.id } }],
            [".", "CPUUtilization", { dimensions = { DBInstanceIdentifier = aws_db_instance.mysql.id } }],
            [".", "FreeableMemory", { dimensions = { DBInstanceIdentifier = aws_db_instance.mysql.id } }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Metrics"
        }
      }
    ]
  })
}

# ===================================
# CloudWatch Alarms
# ===================================
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "student-records-unhealthy-hosts-phase6"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Alert when there are unhealthy hosts"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.application.arn_suffix
    LoadBalancer = aws_lb.application.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "student-records-rds-cpu-high-phase6"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when RDS CPU exceeds 80%"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }
}
