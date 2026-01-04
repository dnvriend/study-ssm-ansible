# 400-data - Data Layer

This layer provisions data storage infrastructure.

## Resources Created

- S3 bucket with versioning, encryption, and lifecycle policies
- RDS PostgreSQL instance (optional)
- Security groups for database access

## Dependencies

- **100-network**: VPC, private subnets

## Usage

```bash
make layer-init LAYER=400-data ENV=dev
make layer-plan LAYER=400-data ENV=dev
make layer-apply LAYER=400-data ENV=dev
```

## Environment Configuration

| Variable | Dev | Test | Prod |
|----------|-----|------|------|
| enable_s3_bucket | true | true | true |
| enable_rds | false | true | true |
| rds_instance_class | - | db.t3.small | db.t3.medium |
| rds_multi_az | - | false | true |

## Outputs

- `s3_bucket_arn` - S3 bucket ARN
- `rds_endpoint` - RDS connection endpoint
