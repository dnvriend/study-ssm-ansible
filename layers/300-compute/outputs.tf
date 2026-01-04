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
