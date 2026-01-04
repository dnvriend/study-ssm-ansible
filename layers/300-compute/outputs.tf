# 300-compute - Outputs

# Web Server Outputs
output "web_server_ids" {
  description = "List of web server EC2 instance IDs"
  value       = aws_instance.web[*].id
}

output "web_server_public_ips" {
  description = "List of web server public IP addresses"
  value       = aws_instance.web[*].public_ip
}

output "web_server_private_ips" {
  description = "List of web server private IP addresses"
  value       = aws_instance.web[*].private_ip
}

# Application Server Outputs
output "app_server_ids" {
  description = "List of application server EC2 instance IDs"
  value       = aws_instance.app[*].id
}

output "app_server_private_ips" {
  description = "List of application server private IP addresses"
  value       = aws_instance.app[*].private_ip
}

# Bastion Host Outputs
output "bastion_id" {
  description = "Bastion host EC2 instance ID"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Bastion host public IP address"
  value       = aws_instance.bastion.public_ip
}
