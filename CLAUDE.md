# study-ssm-ansible

## Project Overview

This is an AWS infrastructure project using OpenTofu with a layered architecture.

## Technical Stack

- **IaC Tool**: OpenTofu 1.9.0
- **Cloud Provider**: AWS (provider 6.27.0)
- **Region**: eu-central-1
- **CI/CD**: GitLab CI

## Project Structure

```
study-ssm-ansible/
├── layers/                    # Infrastructure layers (ordered by number)
│   ├── 100-network/          # VPC, subnets, routing, NAT
│   ├── 200-iam/              # IAM roles, policies, instance profiles
│   ├── 300-compute/          # EC2, ALB, ASG, ECS clusters
│   ├── 400-data/             # S3 buckets, RDS databases
│   ├── 500-application/      # ECS services, application config
│   ├── 600-dns/              # Route53, ACM certificates
│   └── 700-lambda/           # Lambda functions, API Gateway
├── pipeline/                  # CI/CD and automation scripts
├── setup/                     # State backend bootstrap (S3 + DynamoDB)
├── Makefile                  # Developer commands
└── .gitlab-ci.yml            # CI/CD pipeline
```

## Layer Dependencies

- **100-network**: Base layer, no dependencies
- **200-iam**: Base layer, no dependencies
- **300-compute**: Depends on 100-network, 200-iam
- **400-data**: Depends on 100-network
- **500-application**: Depends on 100-network, 200-iam, 300-compute, 400-data
- **600-dns**: Depends on 300-compute
- **700-lambda**: Depends on 100-network, 200-iam

## Environments

| Environment | CIDR | Purpose |
|-------------|------|---------|
| dev | 10.0.0.0/16 | Development |
| test | 10.1.0.0/16 | Testing |
| prod | 10.2.0.0/16 | Production |

## Common Commands

```bash
# Layer operations
make layer-plan LAYER=<layer> ENV=<env>
make layer-apply LAYER=<layer> ENV=<env>
make layer-destroy LAYER=<layer> ENV=<env>
make layer-outputs LAYER=<layer> ENV=<env>

# Batch operations
make plan-all ENV=<env>
make apply-all ENV=<env>

# Development
make fmt          # Format files
make validate     # Validate layers
make clean        # Clean temp files
```

## Code Style

- Use snake_case for resource names and variables
- Use descriptive resource names with environment prefix
- Group related resources in separate .tf files
- Document all variables and outputs
- Use default tags via provider configuration

## Adding New Resources

1. Identify the appropriate layer
2. Add resources to existing .tf files or create new ones
3. Add variables to `variables.tf`
4. Add outputs to `outputs.tf`
5. Update environment tfvars files
6. Update layer README.md
