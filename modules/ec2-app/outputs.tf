output "instance_id" {
  description = "Instance ID"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IP"
  value       = var.create_eip ? aws_eip.app[0].public_ip : aws_instance.app.public_ip
}

output "private_ip" {
  description = "Private IP"
  value       = aws_instance.app.private_ip
}

