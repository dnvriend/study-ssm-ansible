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
  description = "Environment name (dev, test, prod, sandbox)"
  type        = string
  default     = "dev"
}
