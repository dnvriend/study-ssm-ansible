# S3 bucket outputs

output "ssm_logs_bucket_name" {
  description = "Name of the S3 bucket for SSM association logs"
  value       = aws_s3_bucket.ssm_logs.id
}

output "ssm_logs_bucket_arn" {
  description = "ARN of the S3 bucket for SSM association logs"
  value       = aws_s3_bucket.ssm_logs.arn
}

output "ssm_logs_bucket_region" {
  description = "AWS region of the S3 bucket"
  value       = aws_s3_bucket.ssm_logs.region
}

# SSM Association outputs

output "association_ids" {
  description = "Map of all SSM association IDs by role"
  value = {
    common  = aws_ssm_association.common_config.id
    web     = aws_ssm_association.web_servers.id
    app     = aws_ssm_association.app_servers.id
    bastion = aws_ssm_association.bastion.id
  }
}

output "association_names" {
  description = "Map of all SSM association names"
  value = {
    common  = aws_ssm_association.common_config.association_name
    web     = aws_ssm_association.web_servers.association_name
    app     = aws_ssm_association.app_servers.association_name
    bastion = aws_ssm_association.bastion.association_name
  }
}

output "association_schedule" {
  description = "Schedule expression for associations"
  value       = var.association_schedule
}

# SSM Parameter outputs

output "parameter_arns" {
  description = "Map of all SSM parameter ARNs"
  value = {
    app_database_url       = aws_ssm_parameter.app_database_url.arn
    app_secret_key         = aws_ssm_parameter.app_secret_key.arn
    nginx_worker_processes = aws_ssm_parameter.nginx_worker_processes.arn
    environment_name       = aws_ssm_parameter.environment_name.arn
  }
}

output "parameter_names" {
  description = "Map of all SSM parameter names"
  value = {
    app_database_url       = aws_ssm_parameter.app_database_url.name
    app_secret_key         = aws_ssm_parameter.app_secret_key.name
    nginx_worker_processes = aws_ssm_parameter.nginx_worker_processes.name
    environment_name       = aws_ssm_parameter.environment_name.name
  }
  sensitive = true
}

output "github_token_parameter_name" {
  description = "Name of the GitHub token parameter (must be created manually)"
  value       = "/study-ssm-ansible/github/token"
}

output "s3_log_prefixes" {
  description = "S3 key prefixes for each association's logs"
  value = {
    common  = "associations/common/"
    web     = "associations/web/"
    app     = "associations/app/"
    bastion = "associations/bastion/"
  }
}
