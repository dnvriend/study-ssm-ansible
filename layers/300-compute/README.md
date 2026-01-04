# 300-compute - Compute Layer

This layer provisions compute infrastructure.

## Resources Created

- Application Load Balancer with target groups
- Launch Template with Amazon Linux 2023
- Auto Scaling Group
- Security Groups for ALB and EC2
- ECS Cluster with Fargate (optional)

## Dependencies

- **100-network**: VPC, subnets
- **200-iam**: Instance profiles, roles

## Usage

```bash
# Ensure dependencies are deployed first
make layer-apply LAYER=100-network ENV=dev
make layer-apply LAYER=200-iam ENV=dev

# Then deploy compute
make layer-init LAYER=300-compute ENV=dev
make layer-plan LAYER=300-compute ENV=dev
make layer-apply LAYER=300-compute ENV=dev
```

## Environment Configuration

| Variable | Dev | Test | Prod |
|----------|-----|------|------|
| instance_type | t3.micro | t3.small | t3.medium |
| asg_min_size | 1 | 1 | 2 |
| asg_max_size | 2 | 3 | 6 |
| enable_ecs_cluster | false | false | true |

## Outputs

- `alb_dns_name` - ALB DNS for accessing the application
- `ecs_cluster_arn` - ECS cluster ARN (if enabled)
