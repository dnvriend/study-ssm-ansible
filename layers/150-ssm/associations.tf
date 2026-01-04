# SSM State Manager Associations
# These associations pull Ansible playbooks from GitHub and execute them on target instances

locals {
  # GitHub source info for Ansible playbook retrieval
  github_source_info = jsonencode({
    owner      = var.github_repo_owner
    repository = var.github_repo_name
    path       = var.ansible_path
    getOptions = "branch:${var.github_repo_branch}"
    tokenInfo  = "{{ssm-secure:/study-ssm-ansible/github/token}}"
  })
}

# Association: Common Configuration
# Runs on all instances regardless of role
resource "aws_ssm_association" "common_config" {
  name                = "AWS-ApplyAnsiblePlaybooks"
  association_name    = "study-ssm-ansible-common"
  schedule_expression = var.association_schedule

  targets {
    key    = "tag:Environment"
    values = [var.environment]
  }

  parameters = {
    "SourceInfo"          = local.github_source_info
    "SourceType"          = "GitHub"
    "InstallDependencies" = "True"
    "PlaybookFile"        = "playbooks/common.yml"
    "ExtraVariables"      = "SSM=True ansible_python_interpreter=/usr/bin/python3 environment=${var.environment}"
    "Verbose"             = "-v"
  }

  output_location {
    s3_bucket_name = aws_s3_bucket.ssm_logs.id
    s3_key_prefix  = "associations/common/"
  }

  tags = {
    Name = "common-configuration"
    Type = "SSM-Association"
  }

  lifecycle {
    ignore_changes = [schedule_expression]
  }
}

# Association: Web Server Configuration
# Runs on instances with Role=web tag
resource "aws_ssm_association" "web_servers" {
  name                = "AWS-ApplyAnsiblePlaybooks"
  association_name    = "study-ssm-ansible-web"
  schedule_expression = var.association_schedule

  targets {
    key    = "tag:Role"
    values = ["web"]
  }

  parameters = {
    "SourceInfo"          = local.github_source_info
    "SourceType"          = "GitHub"
    "InstallDependencies" = "True"
    "PlaybookFile"        = "playbooks/web-server.yml"
    "ExtraVariables"      = "SSM=True ansible_python_interpreter=/usr/bin/python3 environment=${var.environment}"
    "Verbose"             = "-v"
  }

  output_location {
    s3_bucket_name = aws_s3_bucket.ssm_logs.id
    s3_key_prefix  = "associations/web/"
  }

  # Wait for common configuration to complete
  depends_on = [aws_ssm_association.common_config]

  tags = {
    Name     = "web-server-configuration"
    Type     = "SSM-Association"
    Role     = "web"
    Priority = "2"
  }

  lifecycle {
    ignore_changes = [schedule_expression]
  }
}

# Association: Application Server Configuration
# Runs on instances with Role=app tag
resource "aws_ssm_association" "app_servers" {
  name                = "AWS-ApplyAnsiblePlaybooks"
  association_name    = "study-ssm-ansible-app"
  schedule_expression = var.association_schedule

  targets {
    key    = "tag:Role"
    values = ["app"]
  }

  parameters = {
    "SourceInfo"          = local.github_source_info
    "SourceType"          = "GitHub"
    "InstallDependencies" = "True"
    "PlaybookFile"        = "playbooks/app-server.yml"
    "ExtraVariables"      = "SSM=True ansible_python_interpreter=/usr/bin/python3 environment=${var.environment}"
    "Verbose"             = "-v"
  }

  output_location {
    s3_bucket_name = aws_s3_bucket.ssm_logs.id
    s3_key_prefix  = "associations/app/"
  }

  # Wait for common configuration to complete
  depends_on = [aws_ssm_association.common_config]

  tags = {
    Name     = "app-server-configuration"
    Type     = "SSM-Association"
    Role     = "app"
    Priority = "2"
  }

  lifecycle {
    ignore_changes = [schedule_expression]
  }
}

# Association: Bastion Host Configuration
# Runs on instances with Role=bastion tag
resource "aws_ssm_association" "bastion" {
  name                = "AWS-ApplyAnsiblePlaybooks"
  association_name    = "study-ssm-ansible-bastion"
  schedule_expression = var.association_schedule

  targets {
    key    = "tag:Role"
    values = ["bastion"]
  }

  parameters = {
    "SourceInfo"          = local.github_source_info
    "SourceType"          = "GitHub"
    "InstallDependencies" = "True"
    "PlaybookFile"        = "playbooks/bastion.yml"
    "ExtraVariables"      = "SSM=True ansible_python_interpreter=/usr/bin/python3 environment=${var.environment}"
    "Verbose"             = "-v"
  }

  output_location {
    s3_bucket_name = aws_s3_bucket.ssm_logs.id
    s3_key_prefix  = "associations/bastion/"
  }

  # Wait for common configuration to complete
  depends_on = [aws_ssm_association.common_config]

  tags = {
    Name       = "bastion-configuration"
    Type       = "SSM-Association"
    Role       = "bastion"
    Priority   = "2"
    Management = "true"
  }

  lifecycle {
    ignore_changes = [schedule_expression]
  }
}
