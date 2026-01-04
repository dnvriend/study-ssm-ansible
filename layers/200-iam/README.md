# 200-iam - IAM Layer

This layer provisions IAM roles, policies, and instance profiles.

## Resources Created

### SSM + Ansible Integration
- **IAM Role**: `ssm-ansible-ec2-role` - Role for EC2 instances managed by SSM and Ansible
- **Managed Policy Attachments**:
  - `AmazonSSMManagedInstanceCore` - SSM core permissions
  - `CloudWatchAgentServerPolicy` - CloudWatch monitoring permissions
- **Inline Policy**: `parameter-store-read` - Read access to Parameter Store with KMS decrypt
- **Instance Profile**: `ssm-ansible-instance-profile` - EC2 instance profile

### Parameter Store Permissions
The SSM role includes a custom inline policy that grants:
- `ssm:GetParameter`, `ssm:GetParameters`, `ssm:GetParametersByPath` on `arn:aws:ssm:region:account:parameter/study-ssm-ansible/*`
- `kms:Decrypt` for SecureString parameters (via SSM service)

## Dependencies

None - can be deployed in parallel with 100-network.

## Usage

```bash
make layer-init LAYER=200-iam ENV=dev
make layer-plan LAYER=200-iam ENV=dev
make layer-apply LAYER=200-iam ENV=dev
```

## Environments

| Environment | Account ID |
|-------------|------------|
| dev         | 123456789012 |
| test        | 123456789012 |
| prod        | 123456789012 |
| sandbox     | 862378407079 |

## Outputs

- `ssm_ansible_role_arn` - ARN of the SSM + Ansible EC2 role
- `ssm_ansible_role_name` - Name of the SSM + Ansible EC2 role
- `ssm_ansible_instance_profile_name` - Name of the SSM + Ansible instance profile
- `ssm_ansible_instance_profile_arn` - ARN of the SSM + Ansible instance profile

## Using with EC2 Instances

To use this role with EC2 instances in layer 300-compute:

```hcl
resource "aws_instance" "example" {
  iam_instance_profile = aws_iam_instance_profile.ssm_ansible_profile.name
  # ... other configuration
}
```
