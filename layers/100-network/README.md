# 100-network - Network Layer

This layer provisions foundational AWS networking infrastructure for the study-ssm-ansible project.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet Gateway                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.10.0.0/16)                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │           Public Route Table (0.0.0.0/0 → IGW)       │   │
│  │  ┌──────────────┐        ┌──────────────┐           │   │
│  │  │ Public Subnet│        │ Public Subnet│           │   │
│  │  │10.10.1.0/24  │        │10.10.2.0/24  │           │   │
│  │  │eu-central-1a │        │eu-central-1b │           │   │
│  │  └──────────────┘        └──────────────┘           │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| VPC | 1 | CIDR 10.10.0.0/16, DNS enabled |
| Internet Gateway | 1 | Public internet access |
| Public Subnets | 2 | 10.10.1.0/24 (1a), 10.10.2.0/24 (1b) |
| Public Route Table | 1 | Routes 0.0.0.0/0 to IGW |
| Route Table Associations | 2 | Associates subnets to public RT |

## Dependencies

None - this is the base network layer.

## Usage

```bash
# Initialize the layer
tofu init

# Plan with specific environment
tofu plan -var-file="envs/sandbox.tfvars"

# Apply changes
tofu apply -var-file="envs/sandbox.tfvars"

# Destroy resources
tofu destroy -var-file="envs/sandbox.tfvars"
```

## Environment Configuration

### Sandbox
| Variable | Value |
|----------|-------|
| vpc_cidr | 10.10.0.0/16 |
| AZs | eu-central-1a, eu-central-1b |
| public_subnet_cidrs | ["10.10.1.0/24", "10.10.2.0/24"] |

## Outputs

| Output | Description |
|--------|-------------|
| vpc_id | VPC identifier |
| vpc_cidr | VPC CIDR block |
| internet_gateway_id | Internet Gateway ID |
| public_subnet_ids | List of public subnet IDs |
| public_subnet_cidrs | List of public subnet CIDR blocks |
| availability_zones | AZs in use |
| public_route_table_id | Public route table ID |

## Resource Tagging

All resources include standard tags:
- Project: study-ssm-ansible
- Environment: (from environment variable)
- Layer: 100-network
- ManagedBy: OpenTofu
