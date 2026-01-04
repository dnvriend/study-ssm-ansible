# 150-ssm - SSM State Manager Layer

This layer provisions AWS Systems Manager (SSM) State Manager associations and Parameter Store parameters for the study-ssm-ansible project.

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                     SSM State Manager                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ Association  │  │ Association  │  │ Association  │        │
│  │ : Common     │  │ : Web        │  │ : App        │        │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘        │
│         │                 │                   │                │
│         ▼                 ▼                   ▼                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ Target:      │  │ Target:      │  │ Target:      │        │
│  │ tag:Env=sbox │  │ tag:Role=web │  │ tag:Role=app │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
└────────────────────────────────────────────────────────────────┘
         │                                      │
         ▼                                      ▼
┌──────────────────┐                  ┌──────────────────┐
│ S3 Logs Bucket   │                  │ Parameter Store  │
│ 7-day retention  │                  │ /study-ssm-ansible│
└──────────────────┘                  └──────────────────┘
```

## Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| S3 Bucket | 1 | SSM association logs storage |
| S3 Lifecycle Rule | 1 | 7-day log retention |
| SSM Parameters | 5 | Configuration for Flask app, Nginx, environment |
| SSM Associations | 4 | Ansible playbook automation per role |

## Dependencies

This layer references (but does not depend on):
- **100-network**: For security group references (via SSM target tags)
- **200-iam**: For instance profile names (via SSM target tags)
- **300-compute**: For EC2 instance tags used as association targets

**Deployment Order**: Deploy after 100-network, 200-iam, and 300-compute to ensure instances are running and can be targeted by associations.

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
| aws_region | eu-central-1 |
| aws_account_id | 862378407079 |
| association_schedule | rate(10 minutes) |
| github_repo_owner | dennisvriend |
| github_repo_name | study-ssm-ansible |
| ansible_path | ansible |

## GitHub Token Setup

SSM associations require a GitHub Personal Access Token (PAT) to retrieve Ansible playbooks from private repositories.

**Create the token:**
```bash
# Store GitHub PAT as SecureString parameter
aws ssm put-parameter \
  --name "/study-ssm-ansible/github/token" \
  --value "ghp_xxxxxxxxxxxx" \
  --type "SecureString" \
  --description "GitHub PAT for SSM Ansible associations" \
  --region eu-central-1
```

**Token Requirements:**
- Scope: `repo` (full repository access)
- Permissions: Read repository contents
- No expiration recommended (or set reminder to rotate)

## Outputs

| Output | Description |
|--------|-------------|
| ssm_logs_bucket_name | S3 bucket name for association logs |
| ssm_logs_bucket_arn | S3 bucket ARN |
| ssm_logs_bucket_region | AWS region of the bucket |

## SSM Associations

| Association | Target | Playbook | Schedule |
|-------------|--------|----------|----------|
| common-configuration | tag:Environment | playbooks/common.yml | rate(10 minutes) |
| web-servers | tag:Role=web | playbooks/web-server.yml | rate(10 minutes) |
| app-servers | tag:Role=app | playbooks/app-server.yml | rate(10 minutes) |
| bastion | tag:Role=bastion | playbooks/bastion.yml | rate(10 minutes) |

## SSM Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| /study-ssm-ansible/app/database_url | String | Flask app database URL |
| /study-ssm-ansible/app/secret_key | SecureString | Flask app secret key (random) |
| /study-ssm-ansible/nginx/worker_processes | String | Nginx worker process count |
| /study-ssm-ansible/global/environment | String | Environment name |
| /study-ssm-ansible/github/token | SecureString | GitHub PAT (manual setup) |

## Tag-Based Targeting

SSM associations use EC2 instance tags for targeting:

| Tag | Values | Purpose |
|-----|--------|---------|
| Environment | sandbox, dev, test, prod | Environment-specific configuration |
| Role | web, app, bastion | Role-specific playbooks |
| Stack | demo | Application stack identification |

**Example targeting:**
- `tag:Environment=sandbox` → All instances in sandbox
- `tag:Role=web` → All web servers
- `tag:Environment=sandbox AND tag:Role=web` → Web servers in sandbox

## Viewing Association Logs

```bash
# List recent logs in S3
aws s3 ls s3://study-ssm-ansible-logs-862378407079/associations/ --recursive --human-readable | tail -20

# Download specific log
aws s3 cp s3://study-ssm-ansible-logs-862378407079/associations/common/association-id-run-id/output.json .
```

## Resource Tagging

All resources include standard tags:
- Project: study-ssm-ansible
- Environment: (from terraform.workspace)
- Layer: 150-ssm
- ManagedBy: OpenTofu
