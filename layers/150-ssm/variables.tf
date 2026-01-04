variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "123456789012"
}

variable "environment" {
  description = "Environment name (e.g., dev, test, prod, sandbox)"
  type        = string
}

variable "github_repo_owner" {
  description = "GitHub repository owner for Ansible playbooks"
  type        = string
  default     = "dennisvriend"
}

variable "github_repo_name" {
  description = "GitHub repository name containing Ansible playbooks"
  type        = string
  default     = "study-ssm-ansible"
}

variable "github_repo_branch" {
  description = "GitHub branch to retrieve Ansible playbooks from"
  type        = string
  default     = "main"
}

variable "ansible_path" {
  description = "Path to Ansible playbooks within the GitHub repository"
  type        = string
  default     = "ansible"
}

variable "association_schedule" {
  description = "Schedule expression for SSM associations (minimum 30 minutes for rate-based)"
  type        = string
  default     = "rate(30 minutes)"
}
