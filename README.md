# study-ssm-ansible

AWS infrastructure managed with OpenTofu using a layered approach

## Overview

This project uses a **layered architecture** for AWS infrastructure management with OpenTofu. Each layer represents a logical grouping of resources with explicit dependencies.

## Layer Structure

| Layer | Purpose | Dependencies |
|-------|---------|--------------|
| 100-network | VPC, subnets, routing | None |
| 200-iam | IAM roles, policies, profiles | None |
| 300-compute | EC2, ALB, ASG, ECS | 100-network, 200-iam |
| 400-data | S3, RDS, databases | 100-network |
| 500-application | ECS services, application config | 100-network, 200-iam, 300-compute, 400-data |
| 600-dns | Route53, ACM certificates | 300-compute |
| 700-lambda | Lambda functions, API Gateway | 100-network, 200-iam |

## Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.6.0
- AWS CLI configured with appropriate credentials
- Make

## Quick Start

```bash
# Initialize and plan the network layer
make layer-plan LAYER=100-network ENV=dev

# Apply the network layer
make layer-apply LAYER=100-network ENV=dev

# Continue with other layers in order
make layer-apply LAYER=200-iam ENV=dev
make layer-apply LAYER=300-compute ENV=dev
# ... etc
```

## Project Structure

```
study-ssm-ansible/
├── layers/                    # Infrastructure layers
│   ├── 100-network/          # VPC and networking
│   ├── 200-iam/              # IAM roles and policies
│   ├── 300-compute/          # Compute resources
│   ├── 400-data/             # Data storage
│   ├── 500-application/      # Application services
│   ├── 600-dns/              # DNS and certificates
│   └── 700-lambda/           # Serverless functions
├── pipeline/                  # CI/CD scripts
│   ├── vars.sh               # Environment variables
│   ├── util.sh               # Utility functions
│   ├── plan-layer.sh         # Plan single layer
│   ├── apply-layer.sh        # Apply single layer
│   └── ...
├── setup/                     # State backend bootstrap
├── .gitlab-ci.yml            # GitLab CI/CD pipeline
├── Makefile                  # Development commands
└── README.md
```

## Environments

Three environments are pre-configured: `dev`, `test`, `prod`

Each layer has environment-specific configuration in `layers/<layer>/envs/<env>.tfvars`.

## Commands

### Layer Operations

```bash
# Plan a single layer
make layer-plan LAYER=100-network ENV=dev

# Apply a single layer
make layer-apply LAYER=100-network ENV=dev

# Destroy a single layer
make layer-destroy LAYER=100-network ENV=dev

# View layer outputs
make layer-outputs LAYER=100-network ENV=dev

# View layer state
make layer-state LAYER=100-network ENV=dev
```

### Batch Operations

```bash
# Plan all layers
make plan-all ENV=dev

# Apply all layers
make apply-all ENV=dev

# Destroy all layers (reverse order)
make destroy-all ENV=dev
```

### Development

```bash
# Format all files
make fmt

# Validate all layers
make validate

# Run security checks
make security

# Clean temporary files
make clean
```

## State Management

### Local State (Default)

By default, each layer uses local state files. This is suitable for development.

### S3 Remote State

For production use, set up S3 remote state:

1. Bootstrap the state backend:
   ```bash
   make setup-state
   ```

2. Update each layer's `main.tf` to use S3 backend (see setup/README.md)

3. Migrate existing state:
   ```bash
   cd layers/100-network/
   tofu init -migrate-state
   ```

## CI/CD

This project includes GitLab CI/CD configuration (`.gitlab-ci.yml`):

- **validate**: Format check and validation on all branches
- **plan**: Generate plans on feature branches and main
- **approve**: Manual approval gate for main branch
- **apply**: Apply changes after approval

Required CI/CD variables:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Configuration

### Adding a New Layer

1. Create directory: `layers/XXX-name/`
2. Add required files:
   - `main.tf` - Backend and provider config
   - `variables.tf` - Input variables
   - `outputs.tf` - Outputs for dependent layers
   - `envs/dev.tfvars`, `envs/test.tfvars`, `envs/prod.tfvars`
   - `README.md` - Documentation
3. Update `pipeline/vars.sh` LAYER_ORDER array
4. Update `pipeline/util.sh` get_layer_dependencies function

### Cross-Layer References

Layers reference outputs from dependencies via remote state:

```hcl
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../100-network/terraform.tfstate"
  }
}

# Use: data.terraform_remote_state.network.outputs.vpc_id
```

## License

MIT

