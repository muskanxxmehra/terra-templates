################################################################################
# Terraform Variables Example
# 
# For Local Use:
#   cp terraform.tfvars.example terraform.tfvars
#   # Edit values
#
# For Terraform Cloud:
#   Set these as Terraform Variables in your workspace
#   Mark db_password as "Sensitive"
################################################################################

# General
aws_region   = "ap-south-1"
project_name = "webapp-project"
environment  = "dev"

# REQUIRED: Your AWS SSH key pair name
key_name = "my-key-pair"

# Network
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

# Security
ssh_allowed_cidr = ["0.0.0.0/0"]  # Restrict in production!

# Application Server
app_name          = "flask-app"
app_instance_type = "t3.micro"
app_volume_size   = 8
app_port          = 5000
create_app_eip    = false

# Database Server
db_instance_type = "t3.micro"
db_volume_size   = 8
db_name          = "appdb"
db_user          = "appuser"
db_password      = "YourSecurePassword123!"  # Change this!
db_port          = 3306

# Additional tags
tags = {
  Owner   = "Azalio Team"
  Purpose = "webapp-demo"
}

