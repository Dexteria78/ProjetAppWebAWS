# ==============================================================================
# Launch Template - Phase 3
# ==============================================================================
# Définit le modèle de lancement pour les instances EC2 de l'Auto Scaling Group.
# Basé sur la configuration EC2 de la Phase 2.
# ==============================================================================

resource "aws_launch_template" "web" {
  name_prefix   = "student-records-app-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab.name
  }

  vpc_security_group_ids = [aws_security_group.web_server.id]

  user_data = base64encode(file("${path.module}/userdata.sh"))

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.volume_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "student-records-app-web-server-asg"
      Project     = "student-records-app"
      Environment = "phase3"
      Phase       = "3"
    }
  }

  tags = {
    Name        = "student-records-app-launch-template"
    Project     = "student-records-app"
    Environment = "phase3"
  }
}
