# ──────────────────────────────────────────────────────────
# RDS Module — PostgreSQL database in private subnet
# Creates: DB Subnet Group, Security Group, RDS Instance
# ──────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet"
  description = "Database subnet group for ${var.project_name}"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# ──────────────── Security Group ────────────────
# Only allows PostgreSQL traffic from the EC2 security group
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  description = "Security group for RDS — allows access only from EC2"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ec2_security_group_id]
  }

  # No egress needed for RDS (it doesn't initiate outbound connections)

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ──────────────── RDS Instance ────────────────
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  # Engine
  engine         = "postgres"
  engine_version = "15.4"

  # Size
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # Private subnet only
  multi_az               = false # Set to true for production

  # Backup
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Protection
  deletion_protection = false # Set to true for production
  skip_final_snapshot = true  # Set to false for production
  # final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot"

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres"
  }
}
