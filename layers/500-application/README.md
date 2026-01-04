# 500-application - Application Layer

This layer provisions application-level infrastructure.

## Resources Created

- ECS Task Definition (Fargate)
- ECS Service with ALB integration
- Application-specific security groups
- CloudWatch Log Groups

## Dependencies

- **100-network**: VPC, subnets
- **200-iam**: Task execution roles
- **300-compute**: ECS cluster, ALB
- **400-data**: Database endpoints (optional)

## Usage

```bash
make layer-init LAYER=500-application ENV=dev
make layer-plan LAYER=500-application ENV=dev
make layer-apply LAYER=500-application ENV=dev
```

## Notes

The ECS service requires an ECS cluster from 300-compute (enable_ecs_cluster=true).
