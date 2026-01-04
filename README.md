# study-ssm-ansible

AWS infrastructure managed with OpenTofu using a layered approach

## Overview

This project uses a **layered architecture** for AWS infrastructure management with OpenTofu. Each layer represents a logical grouping of resources with explicit dependencies.

---

## SSM + Ansible Study Project

A hands-on study project demonstrating AWS Systems Manager + Ansible integration for scalable, pull-based configuration management.

### Overview

This project implements a 5-instance environment managed entirely through SSM State Manager and Ansible, demonstrating:
- Pull-based configuration management (no SSH required)
- Tag-based targeting for server groups
- Deterministic configuration with periodic enforcement
- Scalable patterns for hundreds of servers

### Architecture

- **5 EC2 Instances**: 2 web (Nginx), 2 app (Flask), 1 bastion
- **Network**: VPC 10.10.0.0/16 with 2 public subnets
- **Configuration**: Ansible playbooks executed via SSM every 30 minutes
- **Management**: GitHub repo + SSM State Manager + Parameter Store

### Quick Start

1. **Prerequisites**: AWS account (sandbox-ilionx-amf), OpenTofu, GitHub PAT
2. **Deploy**: See [DEPLOYMENT_GUIDE.md](references/DEPLOYMENT_GUIDE.md)
3. **Learn**: Read [SSM_CONCEPTS.md](references/SSM_CONCEPTS.md) and [ANSIBLE_CONCEPTS.md](references/ANSIBLE_CONCEPTS.md)

### Documentation

- [Design Documentation](references/DESIGN.md) - Architecture and decisions
- [Deployment Guide](references/DEPLOYMENT_GUIDE.md) - Step-by-step deployment
- [SSM Concepts](references/SSM_CONCEPTS.md) - Systems Manager learning
- [Ansible Concepts](references/ANSIBLE_CONCEPTS.md) - Ansible patterns for SSM
- [Troubleshooting](references/TROUBLESHOOTING.md) - Common issues and solutions
- [Scaling Patterns](references/SCALING_PATTERNS.md) - Patterns for 100+ servers

### Project Structure

```
study-ssm-ansible/
├── ansible/              # Ansible playbooks and roles
├── layers/               # Terraform infrastructure layers
│   ├── 100-network/     # VPC, subnets, security groups
│   ├── 150-ssm/         # SSM associations and parameters
│   ├── 200-iam/         # IAM roles for SSM
│   └── 300-compute/     # EC2 instances
└── references/          # Learning documentation
```

### Key Learning Outcomes

- SSM State Manager associations and scheduling
- Pull model vs push model configuration management
- IAM roles and Parameter Store integration
- Tag-based server targeting at scale
- Ansible best practices for SSM integration
- Drift detection and remediation

### Cost

Approximately $30-50/month for sandbox environment. Destroy with `make destroy-all ENV=sandbox` when done.

---

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

### SSM Management

```bash
# Check SSM managed instances
make ssm-check

# Manually trigger SSM associations
make ssm-trigger ENV=dev

# View recent SSM association logs
make ssm-logs

# Connect to instance via Session Manager
make ssm-session
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

