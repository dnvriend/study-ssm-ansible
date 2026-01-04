terraform {
  required_version = ">= 1.6.0"

  backend "local" {}

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
      Project     = "study-ssm-ansible"
      Environment = terraform.workspace
      Layer       = "300-compute"
      ManagedBy   = "OpenTofu"
    }
  }
}
