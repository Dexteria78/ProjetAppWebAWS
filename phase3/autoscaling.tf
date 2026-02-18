# ==============================================================================
# Auto Scaling Group - Phase 3
# ==============================================================================
# Configure l'Auto Scaling Group pour gérer automatiquement le nombre d'instances
# en fonction de la charge. Minimum 2 instances (haute disponibilité), maximum 5.
# ==============================================================================

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                = "student-records-app-asg"
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = 2
  max_size         = 5
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # Attendre que l'instance RDS et les secrets soient créés
  depends_on = [
    aws_db_instance.main,
    aws_secretsmanager_secret_version.app_db_credentials
  ]

  tag {
    key                 = "Name"
    value               = "student-records-app-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "student-records-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "phase3"
    propagate_at_launch = true
  }
}

# ==============================================================================
# Scaling Policies - Target Tracking
# ==============================================================================

# Policy de scaling basée sur l'utilisation CPU (target: 70%)
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "student-records-app-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Policy de scaling basée sur le nombre de requêtes par target (ALB)
resource "aws_autoscaling_policy" "request_count_target_tracking" {
  name                   = "student-records-app-request-count-tracking"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.web.arn_suffix}"
    }
    target_value = 1000.0
  }
}
