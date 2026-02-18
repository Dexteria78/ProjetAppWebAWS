# ==============================================================================
# Data Sources - Phase 3
# ==============================================================================

# AMI Ubuntu 22.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Instance Profile (LabInstanceProfile pour AWS Academy)
data "aws_iam_instance_profile" "lab" {
  name = "LabInstanceProfile"
}
