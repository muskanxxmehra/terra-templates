################################################################################
# AWS App + DB Service - Outputs
################################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "app_server_public_ip" {
  description = "Public IP of the application server"
  value       = module.app.public_ip
}

output "app_server_private_ip" {
  description = "Private IP of the application server"
  value       = module.app.private_ip
}

output "db_server_public_ip" {
  description = "Public IP of the database server"
  value       = module.db.public_ip
}

output "db_server_private_ip" {
  description = "Private IP of the database server"
  value       = module.db.private_ip
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "db_user" {
  description = "Database username"
  value       = var.db_user
}

output "app_url" {
  description = "Application URL"
  value       = "http://${module.app.public_ip}:${var.app_port}"
}

#------------------------------------------------------------------------------
# Connection Commands
#------------------------------------------------------------------------------

output "ssh_commands" {
  description = "SSH commands to connect to servers"
  value       = <<-EOT

=== SSH Commands ===

App Server:
  ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${module.app.public_ip}

DB Server:
  ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${module.db.public_ip}

=== Application ===

Web UI:
  http://${module.app.public_ip}:${var.app_port}

API Endpoints:
  http://${module.app.public_ip}:${var.app_port}/api/users
  http://${module.app.public_ip}:${var.app_port}/api/orders
  http://${module.app.public_ip}:${var.app_port}/health

=== Database ===

MySQL CLI (from DB server):
  mysql -u ${var.db_user} -p ${var.db_name}

=== Troubleshooting ===

Check user_data logs:
  ssh -i ~/.ssh/${var.key_name}.pem ec2-user@<IP> "sudo cat /var/log/user-data.log"

Check services:
  ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${module.app.public_ip} "sudo systemctl status flask-app"
  ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${module.db.public_ip} "sudo systemctl status mariadb"

EOT
}

#------------------------------------------------------------------------------
# For Oracle Migration (Use Case 2)
#------------------------------------------------------------------------------

output "migration_info" {
  description = "Information for Oracle database migration"
  value       = <<-EOT

=== Oracle Migration (Use Case 2) ===

1. Export data from MariaDB:
   ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${module.db.public_ip}
   
   mysql -u ${var.db_user} -p'<password>' ${var.db_name} -e "SELECT * FROM users" | tr '\t' ',' > /tmp/users.csv
   mysql -u ${var.db_user} -p'<password>' ${var.db_name} -e "SELECT * FROM orders" | tr '\t' ',' > /tmp/orders.csv

2. Download CSV files:
   scp -i ~/.ssh/${var.key_name}.pem ec2-user@${module.db.public_ip}:/tmp/users.csv .
   scp -i ~/.ssh/${var.key_name}.pem ec2-user@${module.db.public_ip}:/tmp/orders.csv .

3. Upload to OCI Object Storage

4. Import using DBMS_CLOUD.COPY_DATA in Oracle Autonomous DB

EOT
}

