# State Backend Setup

This directory contains the bootstrap configuration for the OpenTofu remote state backend.

## Resources Created

- **S3 Bucket**: `123456789012-tf-state`
  - Versioning enabled
  - Server-side encryption (AES256)
  - Public access blocked
  - Old version cleanup (90 days)

- **DynamoDB Table**: `terraform_lock_123456789012`
  - Used for state locking
  - Pay-per-request billing

## Usage

Run this configuration once before using the main infrastructure layers:

```bash
cd setup/
tofu init
tofu apply
```

## Migrating Layers to S3 Backend

After running this setup, update each layer's `main.tf` to use S3 backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "123456789012-tf-state"
    key            = "env:/${terraform.workspace}/terraform.100-network.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform_lock_123456789012"
    encrypt        = true
  }
}
```

Then run:

```bash
cd layers/100-network/
tofu init -migrate-state
```

## Important

- This setup uses local state - do NOT migrate it to S3
- The S3 bucket has `prevent_destroy` lifecycle protection
- Keep the `setup/terraform.tfstate` file secure
