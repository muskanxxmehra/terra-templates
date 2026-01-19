################################################################################
# AWS App + DB Service - Variables
# Configure in Terraform Cloud or terraform.tfvars
################################################################################

#------------------------------------------------------------------------------
# General Settings
#------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "webapp-project"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Network Settings
#------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

#------------------------------------------------------------------------------
# Security Settings
#------------------------------------------------------------------------------

variable "key_name" {
  description = "Name of the SSH key pair for EC2 instances"
  type        = string
  default     = "my-key-pair"
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 5000
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

#------------------------------------------------------------------------------
# Application Server Settings
#------------------------------------------------------------------------------

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "flask-app"
}

variable "app_instance_type" {
  description = "EC2 instance type for app server"
  type        = string
  default     = "t2.micro"
}

variable "app_volume_size" {
  description = "Root volume size in GB for app server"
  type        = number
  default     = 8
}

variable "create_app_eip" {
  description = "Whether to create an Elastic IP for the app server"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Database Server Settings
#------------------------------------------------------------------------------

variable "db_instance_type" {
  description = "EC2 instance type for DB server"
  type        = string
  default     = "t2.micro"
}

variable "db_volume_size" {
  description = "Root volume size in GB for DB server"
  type        = number
  default     = 8
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

