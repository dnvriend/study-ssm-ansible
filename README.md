# study-ssm-ansible

AWS Systems Manager + Ansible integration for pull-based configuration management at scale.

## Overview

OpenTofu infrastructure demonstrating SSM State Manager with Ansible playbooks for deterministic, SSH-free configuration management.

**Architecture**: 5 EC2 instances (2 web/Nginx, 2 app/Flask, 1 bastion) managed via tag-based SSM associations running every 30 minutes.

## Quick Start

```bash
# Deploy infrastructure
make layer-apply LAYER=100-network ENV=dev
make layer-apply LAYER=200-iam ENV=dev
make layer-apply LAYER=300-compute ENV=dev
make layer-apply LAYER=150-ssm ENV=dev

# Upload GitHub token
export AWS_REGION=eu-central-1
./scripts/upload-github-token.sh

# Validate deployment
./scripts/validate-deployment.sh --full
```

## Documentation

- [Deployment Guide](references/DEPLOYMENT_GUIDE.md) - Step-by-step setup
- [Design](references/DESIGN.md) - Architecture decisions
- [SSM Concepts](references/SSM_CONCEPTS.md) - Systems Manager learning
- [Ansible Concepts](references/ANSIBLE_CONCEPTS.md) - Ansible patterns for SSM
- [Troubleshooting](references/TROUBLESHOOTING.md) - Common issues
- [Validation Scripts](scripts/README.md) - Testing tools

## Project Structure

```
study-ssm-ansible/
├── ansible/              # Playbooks and roles
├── layers/               # Infrastructure layers
│   ├── 100-network/     # VPC, subnets, security groups
│   ├── 150-ssm/         # SSM associations, Parameter Store
│   ├── 200-iam/         # IAM roles for SSM
│   └── 300-compute/     # EC2 instances
├── scripts/             # Validation and management scripts
└── references/          # Documentation
```

## Layer Structure

| Layer | Purpose | Dependencies |
|-------|---------|--------------|
| 100-network | VPC, subnets, routing | None |
| 200-iam | IAM roles, policies | None |
| 300-compute | EC2 instances | 100-network, 200-iam |
| 150-ssm | SSM associations, parameters | 100-network, 200-iam, 300-compute |

## Commands

### Layer Operations

```bash
make layer-plan LAYER=<layer> ENV=<env>
make layer-apply LAYER=<layer> ENV=<env>
make layer-destroy LAYER=<layer> ENV=<env>
make layer-outputs LAYER=<layer> ENV=<env>
```

### SSM Management

```bash
make ssm-check              # Check SSM Fleet status
make ssm-trigger ENV=dev    # Trigger associations
make ssm-logs               # View association logs
make ssm-session            # Connect via Session Manager
```

### Validation

```bash
./scripts/validate-deployment.sh --quick   # Quick check
./scripts/validate-deployment.sh --full    # Comprehensive test
./scripts/check-ssm-fleet.sh               # Fleet status
./scripts/test-web-servers.sh              # Nginx test
./scripts/test-app-servers.sh              # Flask test
```

## Prerequisites

- OpenTofu >= 1.6.0
- AWS CLI configured
- GitHub Personal Access Token (repo scope)
- Make, jq, curl

## Learning Outcomes

- SSM State Manager associations and scheduling
- Pull vs push configuration management
- Tag-based targeting at scale
- IAM roles and Parameter Store integration
- Ansible patterns for SSM
- Drift detection and remediation

## License

MIT
