# SSM Parameters for application configuration

resource "random_password" "app_secret" {
  length  = 32
  special = true

  keepers = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "app_database_url" {
  name        = "/study-ssm-ansible/app/database_url"
  description = "Database URL for Flask application"
  type        = "String"
  value       = "sqlite:///app.db"

  tags = {
    Name = "app-database-url"
    Type = "Application-Config"
  }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_secret_key" {
  name        = "/study-ssm-ansible/app/secret_key"
  description = "Secret key for Flask session encryption"
  type        = "SecureString"
  key_id      = "alias/aws/ssm"
  value       = random_password.app_secret.result

  tags = {
    Name = "app-secret-key"
    Type = "Application-Secret"
  }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "nginx_worker_processes" {
  name        = "/study-ssm-ansible/nginx/worker_processes"
  description = "Number of Nginx worker processes"
  type        = "String"
  value       = "2"

  tags = {
    Name = "nginx-worker-processes"
    Type = "Nginx-Config"
  }
}

resource "aws_ssm_parameter" "environment_name" {
  name        = "/study-ssm-ansible/global/environment"
  description = "Environment name for all instances"
  type        = "String"
  value       = var.environment

  tags = {
    Name = "environment-name"
    Type = "Global-Config"
  }
}

# GitHub token parameter - must be created manually via AWS CLI
# aws ssm put-parameter --name "/study-ssm-ansible/github/token" \
#   --type "SecureString" --value "<YOUR_GITHUB_TOKEN>" \
#   --description "GitHub Personal Access Token for Ansible playbook retrieval"
