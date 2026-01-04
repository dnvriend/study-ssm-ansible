# SSM Layer Configuration - Dev Environment

aws_account_id = "862378407079"
aws_region     = "eu-central-1"
environment    = "dev"

# GitHub Repository Configuration
github_repo_owner  = "dnvriend"
github_repo_name   = "study-ssm-ansible"
github_repo_branch = "main"
ansible_path       = "ansible"

# Association Schedule (minimum 30 minutes for rate-based)
association_schedule = "rate(30 minutes)"
