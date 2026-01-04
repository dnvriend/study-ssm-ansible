# Deployment Guide - SSM + Ansible Study Project

This guide provides step-by-step instructions for deploying the SSM + Ansible study project infrastructure.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Phase 1: GitHub Setup](#phase-1-github-setup)
3. [Phase 2: Store GitHub Token](#phase-2-store-github-token)
4. [Phase 3: Deploy Infrastructure](#phase-3-deploy-infrastructure)
5. [Phase 4: Verify SSM Registration](#phase-4-verify-ssm-registration)
6. [Phase 5: Trigger Associations](#phase-5-trigger-associations)
7. [Phase 6: Verification and Testing](#phase-6-verification-and-testing)
8. [Phase 7: Testing Configuration Drift](#phase-7-testing-configuration-drift)
9. [Cleanup](#cleanup)

---

## Prerequisites

### Required Accounts and Tools

| Requirement | Details |
|-------------|---------|
| **AWS Account** | sandbox-ilionx-amf (Account ID: 862378407079) |
| **AWS CLI** | Version 2.x, configured with credentials |
| **OpenTofu** | Version 1.9.0 or later |
| **Git** | For cloning and managing the repository |
| **GitHub Account** | For storing Ansible playbooks |

### Verify AWS CLI Configuration

```bash
# Check AWS CLI version
aws --version
# Expected output: aws-cli/2.x.x

# Verify credentials
aws sts get-caller-identity
# Expected output:
# {
#   "UserId": "AIDAI...",
#   "Account": "862378407079",
#   "Arn": "arn:aws:iam::862378407079:user/..."
# }
```

### Verify OpenTofu Installation

```bash
# Check OpenTofu version
tofu --version
# Expected output: OpenTofu v1.9.0

# Verify OpenTofu is in PATH
which tofu
# Expected output: /usr/local/bin/tofu (or similar)
```

### Clone Repository (if not already done)

```bash
git clone https://github.com/dennisvriend/study-ssm-ansible.git
cd study-ssm-ansible
```

---

## Phase 1: GitHub Setup

### 1.1 Create GitHub Personal Access Token (PAT)

SSM State Manager requires a GitHub PAT to access your private repository containing Ansible playbooks.

**Steps:**

1. Navigate to GitHub Settings: https://github.com/settings/tokens
2. Click **"Generate new token"** (or "Generate new token (classic)")
3. Configure the token:
   - **Note**: Enter `ssm-ansible-study` for identification
   - **Expiration**: Choose appropriate expiration (90 days recommended)
   - **Scopes**: Select `repo` (Full control of private repositories)
4. Click **"Generate token"**
5. **Important**: Copy the token immediately. It will not be shown again.

**Token format**: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### 1.2 Verify Repository Structure

Ensure your GitHub repository contains the Ansible playbooks in the correct structure:

```
study-ssm-ansible/
└── ansible/
    ├── playbooks/
    │   ├── common.yml
    │   ├── web-server.yml
    │   ├── app-server.yml
    │   └── bastion.yml
    └── roles/
        ├── common/
        ├── nginx/
        ├── flask-app/
        └── monitoring/
```

**Note**: The deployment will fail if the `ansible/` directory does not exist in your repository.

---

## Phase 2: Store GitHub Token

Store the GitHub PAT securely in AWS SSM Parameter Store. This token is referenced by SSM associations when downloading playbooks.

### 2.1 Store Token as SecureString

```bash
aws ssm put-parameter \
  --name "/study-ssm-ansible/github/token" \
  --value "ghp_your_actual_token_here" \
  --type "SecureString" \
  --description "GitHub PAT for SSM State Manager - Ansible playbook access" \
  --region eu-central-1
```

**Replace** `ghp_your_actual_token_here` with your actual GitHub PAT.

### 2.2 Verify Token Storage

```bash
# Verify parameter exists (cannot read SecureString value directly)
aws ssm get-parameter \
  --name "/study-ssm-ansible/github/token" \
  --with-decryption false \
  --query "Parameter.Name" \
  --output text \
  --region eu-central-1

# Expected output: /study-ssm-ansible/github/token
```

### 2.3 Security Notes

- **SecureString**: The token is encrypted using AWS KMS
- **CloudTrail**: All access attempts are logged in CloudTrail
- **IAM Access**: Only EC2 instances with the SSM role can retrieve this token
- **Rotation**: Rotate the token periodically or when compromised

---

## Phase 3: Deploy Infrastructure

Deploy infrastructure layers in dependency order. Each layer builds upon the previous layers.

### Layer Deployment Order

```
100-network (VPC, subnets, security groups)
    ↓
200-iam (IAM roles and instance profiles)
    ↓
300-compute (EC2 instances)
    ↓
150-ssm (SSM parameters and associations)
```

**Note**: The 150-ssm layer is deployed last because it references outputs from 300-compute.

### 3.1 Deploy 100-network Layer

**Purpose**: VPC, subnets, internet gateway, security groups

```bash
# Initialize the layer
make layer-init LAYER=100-network ENV=sandbox

# Review the plan
make layer-plan LAYER=100-network ENV=sandbox

# Apply the configuration
make layer-apply LAYER=100-network ENV=sandbox
```

**Expected Resources**:
- 1 VPC (10.10.0.0/16)
- 1 Internet Gateway
- 2 Public Subnets (10.10.1.0/24, 10.10.2.0/24)
- 3 Security Groups (web, app, bastion)

**Verification**:
```bash
# Get VPC ID
make layer-outputs LAYER=100-network ENV=sandbox | grep vpc_id
```

### 3.2 Deploy 200-iam Layer

**Purpose**: IAM roles for SSM and instance profiles

```bash
# Initialize the layer
make layer-init LAYER=200-iam ENV=sandbox

# Review the plan
make layer-plan LAYER=200-iam ENV=sandbox

# Apply the configuration
make layer-apply LAYER=200-iam ENV=sandbox
```

**Expected Resources**:
- 1 IAM Role (`ssm-ansible-ec2-role`)
- 2 Managed Policy Attachments (SSM, CloudWatch)
- 1 Inline Policy (Parameter Store read)
- 1 Instance Profile

**Verification**:
```bash
# Get instance profile name
make layer-outputs LAYER=200-iam ENV=sandbox | grep instance_profile_name
```

### 3.3 Deploy 300-compute Layer

**Purpose**: EC2 instances (web, app, bastion)

```bash
# Initialize the layer
make layer-init LAYER=300-compute ENV=sandbox

# Review the plan
make layer-plan LAYER=300-compute ENV=sandbox

# Apply the configuration
make layer-apply LAYER=300-compute ENV=sandbox
```

**Expected Resources**:
- 2 Web Servers (t3.micro, Role=web)
- 2 App Servers (t3.small, Role=app)
- 1 Bastion (t3.micro, Role=bastion)

**Wait Time**: After apply, wait 2-3 minutes for instances to launch and SSM Agent to register.

**Verification**:
```bash
# Get instance IDs and IPs
make layer-outputs LAYER=300-compute ENV=sandbox
```

### 3.4 Deploy 150-ssm Layer

**Purpose**: SSM parameters and State Manager associations

```bash
# Initialize the layer
make layer-init LAYER=150-ssm ENV=sandbox

# Review the plan
make layer-plan LAYER=150-ssm ENV=sandbox

# Apply the configuration
make layer-apply LAYER=150-ssm ENV=sandbox
```

**Expected Resources**:
- 1 S3 Bucket (for association logs)
- 5 SSM Parameters (app config, nginx config, global)
- 4 SSM Associations (common, web, app, bastion)

**Verification**:
```bash
# List SSM associations
aws ssm list-associations \
  --association-filter "key=Name,value=study-ssm-ansible-*" \
  --region eu-central-1
```

---

## Phase 4: Verify SSM Registration

After EC2 instances launch, verify they appear in the SSM console.

### 4.1 Check SSM Instance Information

```bash
aws ssm describe-instance-information \
  --region eu-central-1 \
  --query "InstanceInformationList[*].[InstanceId,PingStatus,PlatformName,IPAddress,ResourceType]" \
  --output table
```

**Expected Output**:

```
-------------------------------------------------------------------
|                  DescribeInstanceInformation                  |
+--------------+------------+------------------+----------------+
| InstanceId   | PingStatus | PlatformName     | IPAddress      |
+--------------+------------+------------------+----------------+
| i-0xxxxxx    | Online     | Amazon Linux 2023| 10.10.1.xxx    |
| i-0yyyyyy    | Online     | Amazon Linux 2023| 10.10.2.xxx    |
| i-0zzzzzz    | Online     | Amazon Linux 2023| 10.10.1.xxx    |
| i-0wwwwww    | Online     | Amazon Linux 2023| 10.10.2.xxx    |
| i-0vvvvvv    | Online     | Amazon Linux 2023| 10.10.1.xxx    |
+--------------+------------+------------------+----------------+
```

**Expected**: 5 instances with `PingStatus: Online`

### 4.2 Troubleshooting Registration Issues

If instances don't appear after 5 minutes:

```bash
# Check instance tags (required for SSM targeting)
aws ec2 describe-instances \
  --region eu-central-1 \
  --filters "Name=tag:Environment,Values=sandbox" \
  --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Role'].Value]" \
  --output table

# Verify IAM instance profile is attached
aws ec2 describe-instances \
  --region eu-central-1 \
  --instance-ids i-0xxxxxx \
  --query "Reservations[0].Instances[0].IamInstanceProfile"

# Connect via Session Manager to check SSM Agent
aws ssm start-session --target i-0xxxxxx --region eu-central-1
# Inside instance:
sudo systemctl status amazon-ssm-agent
```

---

## Phase 5: Trigger Associations

SSM associations run on a schedule (every 10 minutes). For the initial deployment, trigger associations manually.

### 5.1 Trigger Common Configuration Association

The common association must run first (base configuration for all instances).

```bash
# Get association ID for common configuration
COMMON_ASSOC_ID=$(aws ssm list-associations \
  --association-filter "key=Name,value=study-ssm-ansible-common" \
  --region eu-central-1 \
  --query "Associations[0].AssociationId" \
  --output text)

# Trigger the association
aws ssm start-associations \
  --association-id "$COMMON_ASSOC_ID" \
  --region eu-central-1
```

**Expected Output**:
```
{
  "AssociationId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

### 5.2 Monitor Association Execution

```bash
# Watch association status
aws ssm describe-association-executions \
  --association-id "$COMMON_ASSOC_ID" \
  --region eu-central-1 \
  --query "Executions[*].[ExecutionId,Status,ResourceCount]" \
  --output table
```

**Status Timeline**:
- `Pending` → Association queued
- `InProgress` → Ansible playbook running
- `Success` → Configuration applied
- `Failed` → Check error logs in S3

### 5.3 Trigger Role-Specific Associations

After common completes, trigger role-specific associations:

```bash
# Web servers
WEB_ASSOC_ID=$(aws ssm list-associations \
  --association-filter "key=Name,value=study-ssm-ansible-web" \
  --region eu-central-1 \
  --query "Associations[0].AssociationId" \
  --output text)

aws ssm start-associations --association-id "$WEB_ASSOC_ID" --region eu-central-1

# App servers
APP_ASSOC_ID=$(aws ssm list-associations \
  --association-filter "key=Name,value=study-ssm-ansible-app" \
  --region eu-central-1 \
  --query "Associations[0].AssociationId" \
  --output text)

aws ssm start-associations --association-id "$APP_ASSOC_ID" --region eu-central-1

# Bastion
BASTION_ASSOC_ID=$(aws ssm list-associations \
  --association-filter "key=Name,value=study-ssm-ansible-bastion" \
  --region eu-central-1 \
  --query "Associations[0].AssociationId" \
  --output text)

aws ssm start-associations --association-id "$BASTION_ASSOC_ID" --region eu-central-1
```

### 5.4 View Association Logs

```bash
# List recent S3 log files
aws s3 ls s3://study-ssm-ansible-logs-862378407079/associations/ --recursive | tail -20

# Download and view a specific log
aws s3 cp s3://study-ssm-ansible-logs-862378407079/associations/common/i-0xxxxxx/stdout - | less
```

---

## Phase 6: Verification and Testing

After associations complete successfully, verify the infrastructure.

### 6.1 Get Instance Public IPs

```bash
# Get web server IPs
make layer-outputs LAYER=300-compute ENV=sandbox | grep web_server_public_ips

# Get bastion IP
make layer-outputs LAYER=300-compute ENV=sandbox | grep bastion_public_ip
```

### 6.2 Test Web Servers

Web servers should respond with custom Nginx page.

```bash
# Test HTTP response
curl http://<web-server-public-ip>/

# Expected output (HTML):
# <!DOCTYPE html>
# <html>
# <head>
#   <title>SSM Ansible Study - Web Server</title>
# ...
#   <h1>Welcome to ssm-ansible-web-1</h1>
#   <p>Role: Web Server</p>
#   <p>Environment: sandbox</p>
#   <p>Deployed via SSM + Ansible</p>
# ...

# Test with headers
curl -I http://<web-server-public-ip>/

# Expected output:
# HTTP/1.1 200 OK
# Server: nginx
# Content-Type: text/html
```

### 6.3 Test App Servers (via Session Manager)

App servers are not publicly accessible. Connect via Session Manager.

```bash
# Start session
aws ssm start-session --target <app-server-instance-id> --region eu-central-1

# Inside the session:
# Test Flask app
curl http://localhost:5000/

# Expected output (JSON):
# {
#   "hostname": "ssm-ansible-app-1",
#   "environment": "sandbox",
#   "status": "healthy",
#   "timestamp": "2025-01-04T14:30:00Z"
# }

# Test health endpoint
curl http://localhost:5000/health

# Expected output:
# {"status": "ok"}

# Exit session
exit
```

### 6.4 Verify Systemd Services

```bash
# Connect via Session Manager
aws ssm start-session --target <instance-id> --region eu-central-1

# Check Nginx (web servers)
sudo systemctl status nginx

# Expected: Active: active (running)

# Check Flask app (app servers)
sudo systemctl status flask-app

# Expected: Active: active (running)

# Check SSM Agent
sudo systemctl status amazon-ssm-agent

# Expected: Active: active (running)
```

### 6.5 View CloudWatch Metrics

```bash
# List SSM association metrics
aws cloudwatch list-metrics \
  --namespace "AWS/SSM" \
  --region eu-central-1

# View metric statistics
aws cloudwatch get-metric-statistics \
  --namespace "AWS/SSM" \
  --metric-name "SuccessfulAssociations" \
  --dimensions Name=AssociationId,Value=<association-id> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region eu-central-1
```

### 6.6 Check S3 Logs

```bash
# List all association logs
aws s3 ls s3://study-ssm-ansible-logs-862378407079/associations/ --recursive

# View a specific log
aws s3 cp s3://study-ssm-ansible-logs-862378407079/associations/common/i-0xxxxxx/20250104T143000Z/stdout - | less
```

---

## Phase 7: Testing Configuration Drift

Verify that SSM associations automatically restore configuration drift.

### 7.1 Simulate Configuration Drift

```bash
# Connect to a web server
aws ssm start-session --target <web-server-instance-id> --region eu-central-1

# Stop Nginx manually
sudo systemctl stop nginx

# Verify Nginx is stopped
sudo systemctl status nginx

# Expected: Active: inactive (dead)

# Delete index.html
sudo rm -f /usr/share/nginx/html/index.html

# Exit session
exit
```

### 7.2 Wait for Next Association Run

Associations run every 10 minutes. Either wait for the next scheduled run or trigger manually.

```bash
# Trigger manually (optional)
WEB_ASSOC_ID=$(aws ssm list-associations \
  --association-filter "key=Name,value=study-ssm-ansible-web" \
  --region eu-central-1 \
  --query "Associations[0].AssociationId" \
  --output text)

aws ssm start-associations --association-id "$WEB_ASSOC_ID" --region eu-central-1

# Wait 2-3 minutes for execution
```

### 7.3 Verify Configuration Restoration

```bash
# Connect back to the instance
aws ssm start-session --target <web-server-instance-id> --region eu-central-1

# Check Nginx status
sudo systemctl status nginx

# Expected: Active: active (running)

# Verify index.html restored
ls -l /usr/share/nginx/html/index.html

# Expected: File exists with recent timestamp

# Test web response
curl http://localhost/

# Expected: HTML response

# Exit session
exit
```

**Result**: SSM association automatically restored the configuration, demonstrating drift remediation.

---

## Cleanup

Destroy all infrastructure when done studying to avoid ongoing costs.

### Destroy Layers in Reverse Order

```bash
# Destroy 150-ssm layer
make layer-destroy LAYER=150-ssm ENV=sandbox

# Destroy 300-compute layer
make layer-destroy LAYER=300-compute ENV=sandbox

# Destroy 200-iam layer
make layer-destroy LAYER=200-iam ENV=sandbox

# Destroy 100-network layer
make layer-destroy LAYER=100-network ENV=sandbox
```

### 9.2 Verify S3 Bucket Deletion

The S3 log bucket has `force_destroy = true`, so it should delete with the layer.

```bash
# Verify bucket is gone (should error)
aws s3 ls s3://study-ssm-ansible-logs-862378407079/

# Expected output: An error occurred (NoSuchBucket)...
```

### 9.3 Delete SSM Parameter (GitHub Token)

The GitHub token was created manually and will not be destroyed by Terraform.

```bash
# Delete the parameter
aws ssm delete-parameter \
  --name "/study-ssm-ansible/github/token" \
  --region eu-central-1

# Verify deletion (should error)
aws ssm get-parameter \
  --name "/study-ssm-ansible/github/token" \
  --region eu-central-1

# Expected output: An error occurred (ParameterNotFound)...
```

### 9.4 Check for Remaining Resources

```bash
# Check for remaining EC2 instances
aws ec2 describe-instances \
  --region eu-central-1 \
  --filters "Name=tag:Environment,Values=sandbox" \
  --query "Reservations[*].Instances[*].[InstanceId,State.Name]" \
  --output table

# Check for remaining SSM associations
aws ssm list-associations \
  --association-filter "key=Name,value=study-ssm-ansible-*" \
  --region eu-central-1

# Check for remaining SSM parameters
aws ssm get-parameters-by-path \
  --path "/study-ssm-ansible/" \
  --region eu-central-1
```

**Expected**: No resources remaining

### 9.5 Clean Up Local State

```bash
# Clean temporary files
make clean

# Remove local Terraform state files (if using local backend)
rm -rf layers/*/terraform.tfstate
rm -rf layers/*/terraform.tfstate.backup
```

---

## Appendix: Useful Commands

### Makefile Commands

```bash
# View all available commands
make help

# Plan all layers
make plan-all ENV=sandbox

# Apply all layers (in dependency order)
make apply-all ENV=sandbox

# Destroy all layers (in reverse order)
make destroy-all ENV=sandbox

# Show layer outputs
make layer-outputs LAYER=100-network ENV=sandbox
```

### AWS CLI Commands

```bash
# Check SSM managed instances
aws ssm describe-instance-information --region eu-central-1 --output table

# List SSM associations
aws ssm list-associations --region eu-central-1

# List SSM parameters
aws ssm get-parameters-by-path --path "/study-ssm-ansible/" --region eu-central-1

# Start Session Manager session
aws ssm start-session --target <instance-id> --region eu-central-1

# View S3 logs
aws s3 ls s3://study-ssm-ansible-logs-862378407079/associations/ --recursive
```

### Troubleshooting Commands

```bash
# View association execution details
aws ssm describe-association-executions \
  --association-id <association-id> \
  --region eu-central-1

# View specific execution output
aws ssm get-association-execution \
  --association-id <association-id> \
  --execution-id <execution-id> \
  --region eu-central-1

# Download association logs from S3
aws s3 cp s3://study-ssm-ansible-logs-862378407079/associations/<association>/<instance-id>/<timestamp>/stdout -

# Connect via Session Manager for debugging
aws ssm start-session --target <instance-id> --region eu-central-1
```

---

## Cost Reminder

**Estimated Monthly Cost**: ~$39/month

| Resource | Monthly Cost |
|----------|--------------|
| EC2 Instances | $38.57 |
| S3 Storage | <$0.01 |
| Data Transfer | $0.10 |
| SSM Services | Free |

**Remember**: Destroy infrastructure when not studying to avoid unnecessary costs.

```bash
make destroy-all ENV=sandbox
```
