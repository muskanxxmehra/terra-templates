output "instance_id" {
  description = "Instance ID"
  value       = aws_instance.db.id
}

output "public_ip" {
  description = "Public IP"
  value       = aws_instance.db.public_ip
}

output "private_ip" {
  description = "Private IP"
  value       = aws_instance.db.private_ip
}

