# ──────────────────────────────────────────────────────────
# Root Module — Orchestrates all infrastructure components
# ──────────────────────────────────────────────────────────

# Fetch available AZs in the selected region
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_1 = data.aws_availability_zones.available.names[0]
  az_2 = data.aws_availability_zones.available.names[1]
  name_prefix = "${var.project_name}-${var.environment}"
}

# ──────────────────────────────────────────────────────────
# VPC — Network foundation with public and private subnets
# ──────────────────────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  az_1         = local.az_1
  az_2         = local.az_2
}

# ──────────────────────────────────────────────────────────
# Security — IAM roles and instance profiles
# ──────────────────────────────────────────────────────────
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  s3_bucket_arn = module.s3.bucket_arn
}

# ──────────────────────────────────────────────────────────
# EC2 — Application server with Nginx and Docker
# ──────────────────────────────────────────────────────────
module "ec2" {
  source = "./modules/ec2"

  project_name         = var.project_name
  environment          = var.environment
  instance_type        = var.instance_type
  subnet_id            = module.vpc.public_subnet_ids[0]
  vpc_id               = module.vpc.vpc_id
  allowed_ssh_cidr     = var.allowed_ssh_cidr
  key_pair_name        = var.key_pair_name
  instance_profile_name = module.security.instance_profile_name
  alb_security_group_id = module.alb.security_group_id
}

# ──────────────────────────────────────────────────────────
# RDS — PostgreSQL database in private subnet
# ──────────────────────────────────────────────────────────
module "rds" {
  source = "./modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  db_instance_class  = var.db_instance_class
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  ec2_security_group_id = module.ec2.security_group_id
}

# ──────────────────────────────────────────────────────────
# S3 — Encrypted storage bucket with versioning
# ──────────────────────────────────────────────────────────
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

# ──────────────────────────────────────────────────────────
# ALB — Application Load Balancer for traffic distribution
# ──────────────────────────────────────────────────────────
module "alb" {
  source = "./modules/alb"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.public_subnet_ids
  ec2_instance_id = module.ec2.instance_id
}
