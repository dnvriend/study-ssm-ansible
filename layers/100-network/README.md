# 100-network - Network Layer

This layer provisions foundational AWS networking infrastructure.

## Resources Created

- VPC with configurable CIDR block
- Public and private subnets across multiple AZs
- Internet Gateway for public subnet internet access
- NAT Gateway(s) for private subnet outbound access (optional)
- Route tables and associations

## Dependencies

None - this is the base layer.

## Usage

```bash
# From the project root
make layer-init LAYER=100-network ENV=dev
make layer-plan LAYER=100-network ENV=dev
make layer-apply LAYER=100-network ENV=dev
```

## Environment Configuration

| Variable | Dev | Test | Prod |
|----------|-----|------|------|
| vpc_cidr | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| AZs | 2 | 2 | 3 |
| NAT Gateway | disabled | disabled | enabled (per-AZ) |

## Outputs

This layer exports the following outputs for use by dependent layers:

- `vpc_id` - VPC identifier
- `public_subnet_ids` - List of public subnet IDs
- `private_subnet_ids` - List of private subnet IDs
- `availability_zones` - AZs in use
