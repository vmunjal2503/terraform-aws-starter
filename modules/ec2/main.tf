# ──────────────────────────────────────────────────────────
# EC2 Module — Application server
# Creates: EC2 instance with Nginx + Docker, Security Group
# ──────────────────────────────────────────────────────────

# Get latest Ubuntu 22.04 AMI
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

# ──────────────── Security Group ────────────────
resource "aws_security_group" "ec2" {
  name_prefix = "${var.project_name}-${var.environment}-ec2-"
  description = "Security group for EC2 application server"
  vpc_id      = var.vpc_id

  # SSH access — restrict this in production
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # HTTP from ALB only
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ──────────────── EC2 Instance ────────────────
resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = var.instance_profile_name
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  # Bootstrap: install Nginx, Docker, Docker Compose
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    apt-get update -y
    apt-get upgrade -y

    # Install Nginx
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx

    # Install Docker
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker ubuntu

    # Install Docker Compose
    apt-get install -y docker-compose-plugin

    # Install useful tools
    apt-get install -y htop curl jq unzip awscli

    echo "Bootstrap complete" > /var/log/user-data-complete.log
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-app-server"
  }
}
