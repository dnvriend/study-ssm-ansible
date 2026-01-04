# 200-iam - IAM Layer

This layer provisions IAM roles, policies, and instance profiles.

## Resources Created

- EC2 Instance Role with optional SSM and CloudWatch access
- EC2 Instance Profile
- ECS Task Execution Role
- ECS Task Role (for application permissions)
- Lambda Execution Role with VPC access

## Dependencies

None - can be deployed in parallel with 100-network.

## Usage

```bash
make layer-init LAYER=200-iam ENV=dev
make layer-plan LAYER=200-iam ENV=dev
make layer-apply LAYER=200-iam ENV=dev
```

## Outputs

- `ec2_instance_role_arn` - EC2 instance role ARN
- `ec2_instance_profile_name` - Instance profile for EC2
- `ecs_task_execution_role_arn` - ECS task execution role
- `ecs_task_role_arn` - ECS task role for app permissions
- `lambda_execution_role_arn` - Lambda execution role
