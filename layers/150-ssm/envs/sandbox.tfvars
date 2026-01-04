# Environment configuration for sandbox

environment       = "sandbox"
aws_region       = "eu-central-1"
aws_account_id   = "862378407079"

# GitHub configuration for Ansible playbook retrieval
github_repo_owner   = "dennisvriend"
github_repo_name    = "study-ssm-ansible"
github_repo_branch  = "main"
ansible_path        = "ansible"

# SSM association schedule (10-minute intervals for study/testing)
association_schedule = "rate(10 minutes)"
