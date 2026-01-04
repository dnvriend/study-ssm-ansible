# State Backend Bootstrap
#
# This configuration creates the S3 bucket and DynamoDB table
# required for remote state storage.
#
# Run this ONCE before using the main infrastructure layers.
#
# Usage:
#   cd setup/
#   tofu init
#   tofu apply

terraform {
  required_version = ">= 1.6.0"

  # This bootstrap uses local state - do NOT migrate to S3
  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "study-ssm-ansible"
      Purpose   = "terraform-state"
      ManagedBy = "OpenTofu"
    }
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "123456789012"
}

# S3 Bucket for state files
resource "aws_s3_bucket" "state" {
  bucket = "${var.aws_account_id}-tf-state"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "OpenTofu State Bucket"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "lock" {
  name         = "terraform_lock_${var.aws_account_id}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "OpenTofu Lock Table"
  }
}

output "state_bucket_name" {
  description = "S3 bucket for state files"
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  description = "DynamoDB table for state locking"
  value       = aws_dynamodb_table.lock.name
}
