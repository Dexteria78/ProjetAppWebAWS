# Environnement Cloud9 pour la migration de données et l'administration
resource "aws_cloud9_environment_ec2" "migration" {
  name          = "${var.project_name}-cloud9-migration"
  instance_type = "t3.small"
  subnet_id     = aws_subnet.public_1.id
  image_id      = "amazonlinux-2023-x86_64"

  automatic_stop_time_minutes = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
