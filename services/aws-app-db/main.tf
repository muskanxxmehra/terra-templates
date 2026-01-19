################################################################################
# AWS App + DB Service - TERRAFORM ONLY (No Ansible Required)
# 
# This Terraform configuration:
# - Provisions VPC, Security Groups, IAM
# - Creates DB server with MariaDB installed and configured
# - Creates App server with Flask application
# - Seeds sample data (USERS, ORDERS)
#
# Everything is automated via user_data scripts!
################################################################################

terraform {
  required_version = ">= 1.0.0"

  # ============================================================================
  # TERRAFORM CLOUD BACKEND
  # ============================================================================
  cloud {
    organization = "YOUR_ORG_NAME"  # Change this

    workspaces {
      name = "aws-app-db"  # Change this
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Service     = "aws-app-db"
    }
  }
}

################################################################################
# Data Sources
################################################################################

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

################################################################################
# Modules
################################################################################

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = data.aws_availability_zones.available.names[0]
  environment        = var.environment
  tags               = var.tags
}

module "iam" {
  source = "../../modules/iam"

  environment = var.environment
  tags        = var.tags
}

module "security" {
  source = "../../modules/security"

  vpc_id           = module.vpc.vpc_id
  environment      = var.environment
  ssh_allowed_cidr = var.ssh_allowed_cidr
  app_port         = var.app_port
  db_port          = var.db_port
  tags             = var.tags
}

# DB Server - Must be created FIRST (App depends on DB's private IP)
module "db" {
  source = "../../modules/ec2-db"

  ami_id               = data.aws_ami.amazon_linux_2.id
  instance_type        = var.db_instance_type
  subnet_id            = module.vpc.public_subnet_id
  security_group_id    = module.security.db_sg_id
  key_name             = var.key_name
  iam_instance_profile = module.iam.instance_profile_name
  environment          = var.environment
  root_volume_size     = var.db_volume_size
  db_name              = var.db_name
  db_user              = var.db_user
  db_password          = var.db_password
  tags                 = var.tags
}

# App Server - Created AFTER DB (needs DB private IP)
module "app" {
  source = "../../modules/ec2-app"

  ami_id               = data.aws_ami.amazon_linux_2.id
  instance_type        = var.app_instance_type
  subnet_id            = module.vpc.public_subnet_id
  security_group_id    = module.security.app_sg_id
  key_name             = var.key_name
  iam_instance_profile = module.iam.instance_profile_name
  app_name             = var.app_name
  environment          = var.environment
  root_volume_size     = var.app_volume_size
  create_eip           = var.create_app_eip
  app_port             = var.app_port
  
  # Database connection info (passed to user_data)
  db_host     = module.db.private_ip
  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password
  
  tags = var.tags

  # Explicit dependency - wait for DB to be ready
  depends_on = [module.db]
}

