# Deployment Steps - SSM + Ansible Infrastructure

This guide covers the complete deployment process for the SSM + Ansible study project.

## Overview

The infrastructure consists of 4 Terraform layers that must be deployed in order:
1. **100-network** - VPC, subnets, security groups
2. **200-iam** - IAM roles and instance profiles for SSM
3. **300-compute** - EC2 instances (2 web, 2 app, 1 bastion)
4. **150-ssm** - SSM associations, Parameter Store, S3 logging

## Prerequisites

Before starting deployment:

- [x] AWS CLI configured for sandbox-ilionx-amf account (862378407079)
- [x] OpenTofu installed (1.6.0+)
- [ ] GitHub repository pushed with Ansible playbooks
- [ ] GitHub Personal Access Token (PAT) generated

## Step 1: Prepare GitHub Repository

### 1.1 Commit and Push Ansible Playbooks

```bash
# Ensure all Ansible code is committed
git add ansible/
git status

# Commit if needed
git commit -m "Add Ansible playbooks for SSM deployment"

# Push to GitHub main branch
git push origin main
```

### 1.2 Verify GitHub Repository

Visit: https://github.com/dennisvriend/study-ssm-ansible

Ensure the following exist:
- `ansible/playbooks/common.yml`
- `ansible/playbooks/web-server.yml`
- `ansible/playbooks/app-server.yml`
- `ansible/playbooks/bastion.yml`
- `ansible/roles/` directory with all roles

### 1.3 Generate GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Settings:
   - **Name**: `ssm-ansible-study-sandbox`
   - **Expiration**: 90 days (or custom)
   - **Scopes**:
     - ✅ `repo` (Full control of private repositories)
4. Click "Generate token"
5. **Copy the token immediately** (you won't see it again!)

Example token format: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## Step 2: Deploy Infrastructure Layers

### 2.1 Deploy Network Layer (100-network)

```bash
# Navigate to project root
cd /Users/dennisvriend/projects/study-ssm-ansible

# Plan the network layer
./pipeline/plan-layer.sh 100-network sandbox

# Review the plan output
# Expected: VPC, 2 subnets, Internet Gateway, 3 security groups, route tables

# Apply the network layer
./pipeline/apply-layer.sh 100-network sandbox

# Verify outputs
./pipeline/outputs.sh 100-network sandbox
```

**Expected Outputs**:
- `vpc_id`: vpc-xxxxx
- `public_subnet_ids`: [subnet-xxxxx, subnet-yyyyy]
- `web_security_group_id`: sg-xxxxx
- `app_security_group_id`: sg-yyyyy
- `bastion_security_group_id`: sg-zzzzz

### 2.2 Deploy IAM Layer (200-iam)

```bash
# Plan the IAM layer
./pipeline/plan-layer.sh 200-iam sandbox

# Review the plan output
# Expected: IAM role, instance profile, policies

# Apply the IAM layer
./pipeline/apply-layer.sh 200-iam sandbox

# Verify outputs
./pipeline/outputs.sh 200-iam sandbox
```

**Expected Outputs**:
- `instance_profile_name`: ssm-ansible-ec2-profile
- `instance_profile_arn`: arn:aws:iam::862378407079:instance-profile/...
- `role_arn`: arn:aws:iam::862378407079:role/ssm-ansible-ec2-role

### 2.3 Deploy Compute Layer (300-compute)

```bash
# Plan the compute layer
./pipeline/plan-layer.sh 300-compute sandbox

# Review the plan output
# Expected: 5 EC2 instances (2 web, 2 app, 1 bastion)

# Apply the compute layer
./pipeline/apply-layer.sh 300-compute sandbox

# Verify outputs
./pipeline/outputs.sh 300-compute sandbox
```

**Expected Outputs**:
- `web_server_ids`: [i-xxxxx, i-yyyyy]
- `web_server_public_ips`: [1.2.3.4, 5.6.7.8]
- `app_server_ids`: [i-aaaaa, i-bbbbb]
- `bastion_id`: i-zzzzz
- `bastion_public_ip`: 9.10.11.12

**⏱️ Important**: Wait 2-3 minutes for instances to:
1. Finish launching
2. SSM agent to initialize
3. Register with AWS Systems Manager

### 2.4 Verify SSM Registration

```bash
# Check if instances are registered with SSM
make ssm-check

# Alternative AWS CLI command:
aws ssm describe-instance-information \
  --region eu-central-1 \
  --query "InstanceInformationList[*].[InstanceId,PingStatus,PlatformName,IPAddress]" \
  --output table
```

**Expected Output**:
```
---------------------------------------------------------
|         DescribeInstanceInformation                   |
+-------------+---------+------------------+------------+
| i-xxxxx     | Online  | Amazon Linux 2023| 10.10.1.x |
| i-yyyyy     | Online  | Amazon Linux 2023| 10.10.2.x |
| i-aaaaa     | Online  | Amazon Linux 2023| 10.10.1.x |
| i-bbbbb     | Online  | Amazon Linux 2023| 10.10.2.x |
| i-zzzzz     | Online  | Amazon Linux 2023| 10.10.1.x |
+-------------+---------+------------------+------------+
```

**Status Must Be**: `Online`

If instances show as `ConnectionLost` or don't appear:
1. Wait another 1-2 minutes
2. Check IAM role is attached to instances
3. Check internet connectivity (public subnets + IGW)
4. See troubleshooting section below

## Step 3: Store GitHub Token in Parameter Store

### 3.1 Store the GitHub PAT

```bash
# Replace ghp_xxxx with your actual token from Step 1.3
aws ssm put-parameter \
  --name "/study-ssm-ansible/github/token" \
  --value "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  --type "SecureString" \
  --region eu-central-1
```

**Expected Output**:
```json
{
    "Version": 1,
    "Tier": "Standard"
}
```

### 3.2 Verify Parameter Storage

```bash
# Verify the parameter exists (value will be hidden)
aws ssm get-parameter \
  --name "/study-ssm-ansible/github/token" \
  --region eu-central-1 \
  --query "Parameter.[Name,Type,LastModifiedDate]" \
  --output table
```

**Expected Output**:
```
---------------------------------------------------------------
|                      GetParameter                           |
+------------------------------------+-------------+-----------+
|  /study-ssm-ansible/github/token   | SecureString| 2026-01-04|
+------------------------------------+-------------+-----------+
```

## Step 4: Deploy SSM Layer (150-ssm)

### 4.1 Plan the SSM Layer

```bash
# Plan the SSM layer
./pipeline/plan-layer.sh 150-ssm sandbox

# Review the plan output
# Expected: 4 SSM associations, 4 parameters, 1 S3 bucket
```

**Expected Resources**:
- S3 bucket: `study-ssm-ansible-logs-862378407079`
- Parameters:
  - `/study-ssm-ansible/app/database_url`
  - `/study-ssm-ansible/app/secret_key`
  - `/study-ssm-ansible/nginx/worker_processes`
  - `/study-ssm-ansible/global/environment`
- Associations:
  - `study-ssm-ansible-common` (targets all instances)
  - `study-ssm-ansible-web` (targets Role=web)
  - `study-ssm-ansible-app` (targets Role=app)
  - `study-ssm-ansible-bastion` (targets Role=bastion)

### 4.2 Apply the SSM Layer

```bash
# Apply the SSM layer
./pipeline/apply-layer.sh 150-ssm sandbox

# Verify outputs
./pipeline/outputs.sh 150-ssm sandbox
```

**Expected Outputs**:
- `s3_bucket_name`: study-ssm-ansible-logs-862378407079
- `common_association_id`: xxxxx-xxxxx-xxxxx
- `web_association_id`: yyyyy-yyyyy-yyyyy
- `app_association_id`: zzzzz-zzzzz-zzzzz
- `bastion_association_id`: aaaaa-aaaaa-aaaaa

## Step 5: Trigger Initial Configuration

SSM associations run on a schedule (every 30 minutes). For immediate configuration, trigger manually:

### 5.1 Trigger Common Configuration

```bash
# Trigger common configuration on all instances
make ssm-trigger ENV=sandbox

# Alternative manual command:
aws ssm send-command \
  --document-name "AWS-ApplyAnsiblePlaybooks" \
  --targets "Key=tag:Environment,Values=sandbox" \
  --parameters file://$(pwd)/layers/150-ssm/trigger-common.json \
  --region eu-central-1
```

### 5.2 Monitor Command Execution

```bash
# List recent commands
aws ssm list-commands \
  --region eu-central-1 \
  --max-results 5 \
  --query "Commands[*].[CommandId,Status,DocumentName,RequestedDateTime]" \
  --output table

# Get detailed command status (replace COMMAND-ID)
aws ssm list-command-invocations \
  --command-id "COMMAND-ID-HERE" \
  --region eu-central-1 \
  --details \
  --query "CommandInvocations[*].[InstanceId,Status,StatusDetails]" \
  --output table
```

**Expected Status**: `Success` or `InProgress`

### 5.3 View Association Logs

```bash
# View recent SSM association logs in S3
make ssm-logs

# Alternative command:
aws s3 ls s3://study-ssm-ansible-logs-862378407079/associations/ --recursive | tail -20

# Download specific log to review
aws s3 cp s3://study-ssm-ansible-logs-862378407079/associations/common/xxxxx/stdout \
  /tmp/ansible-output.log

cat /tmp/ansible-output.log
```

## Step 6: Verify Deployment

### 6.1 Check Web Servers

```bash
# Get web server public IPs
./pipeline/outputs.sh 300-compute sandbox | grep web_server_public_ips

# Test Nginx is responding (replace with actual IP)
curl http://1.2.3.4

# Expected: HTML page with "Welcome to SSM + Ansible Study Project"
```

### 6.2 Check Application Servers via Session Manager

```bash
# Connect to an app server (replace instance ID)
make ssm-session
# Enter instance ID when prompted: i-xxxxx

# Once connected, check Flask app
sudo systemctl status flask-app
curl http://localhost:5000/health

# Exit session
exit
```

### 6.3 Check Bastion Host

```bash
# Connect to bastion
make ssm-session
# Enter bastion instance ID

# Check SSH configuration
sudo cat /etc/ssh/sshd_config | grep -E "PermitRootLogin|PasswordAuthentication"

# Check logs
sudo tail -20 /var/log/secure

# Exit
exit
```

## Step 7: Verify Scheduled Associations

Associations will run automatically every 30 minutes. To verify:

```bash
# List association executions
aws ssm list-association-executions \
  --association-id "xxxxx-xxxxx-xxxxx" \
  --region eu-central-1 \
  --max-results 5 \
  --query "AssociationExecutions[*].[ExecutionId,Status,DetailedStatus,CreatedTime]" \
  --output table
```

## Testing Configuration Drift

To verify SSM's deterministic configuration enforcement:

### Test 1: Modify Nginx Configuration

```bash
# Connect to a web server
make ssm-session
# Enter web server instance ID

# Modify nginx configuration
sudo vi /etc/nginx/nginx.conf
# Make a change (e.g., change worker_processes)

# Restart nginx
sudo systemctl restart nginx

# Exit and wait 30 minutes
exit

# After 30 minutes, reconnect and verify
# SSM should have reverted the change back to the defined state
```

### Test 2: Stop a Service

```bash
# Connect to app server
make ssm-session

# Stop the Flask app
sudo systemctl stop flask-app

# Exit and wait 30 minutes
exit

# After 30 minutes, verify service is running again
# SSM should have restarted it
```

## Cleanup / Teardown

When done studying, destroy resources in **reverse order**:

```bash
# 1. Destroy SSM layer (remove associations first)
./pipeline/destroy-layer.sh 150-ssm sandbox

# 2. Destroy compute instances
./pipeline/destroy-layer.sh 300-compute sandbox

# 3. Destroy IAM resources
./pipeline/destroy-layer.sh 200-iam sandbox

# 4. Destroy network
./pipeline/destroy-layer.sh 100-network sandbox

# 5. Delete GitHub token from Parameter Store
aws ssm delete-parameter \
  --name "/study-ssm-ansible/github/token" \
  --region eu-central-1
```

## Troubleshooting

### Issue: Instances Not Appearing in SSM

**Symptoms**: `make ssm-check` shows no instances

**Solutions**:
1. Wait 2-3 minutes after instance launch
2. Verify IAM instance profile is attached:
   ```bash
   aws ec2 describe-instances \
     --instance-ids i-xxxxx \
     --region eu-central-1 \
     --query "Reservations[0].Instances[0].IamInstanceProfile"
   ```
3. Check SSM agent status:
   ```bash
   # Connect via EC2 Instance Connect or SSH
   sudo systemctl status amazon-ssm-agent
   ```

### Issue: Association Execution Fails

**Symptoms**: Association shows "Failed" status

**Solutions**:
1. Check S3 logs:
   ```bash
   make ssm-logs
   aws s3 cp s3://study-ssm-ansible-logs-862378407079/associations/common/xxxxx/stderr /tmp/error.log
   cat /tmp/error.log
   ```

2. Common errors:
   - **GitHub token invalid**: Regenerate token, update Parameter Store
   - **Playbook syntax error**: Check `ansible-playbook --syntax-check`
   - **Module not found**: Ensure `ansible.builtin.` prefix on all modules

### Issue: GitHub Authentication Fails

**Symptoms**: Association logs show "Authentication failed" or "Repository not found"

**Solutions**:
1. Verify token has correct permissions:
   - Required scope: `repo`
   - Repository: `dennisvriend/study-ssm-ansible` must be accessible
2. Regenerate token if expired
3. Update Parameter Store:
   ```bash
   aws ssm put-parameter \
     --name "/study-ssm-ansible/github/token" \
     --value "NEW-TOKEN-HERE" \
     --type "SecureString" \
     --overwrite \
     --region eu-central-1
   ```

### Issue: Web Server Not Responding

**Symptoms**: `curl http://IP` times out or connection refused

**Solutions**:
1. Check security group allows HTTP (port 80):
   ```bash
   aws ec2 describe-security-groups \
     --group-ids sg-xxxxx \
     --region eu-central-1 \
     --query "SecurityGroups[0].IpPermissions"
   ```

2. Check Nginx is running:
   ```bash
   make ssm-session  # Connect to web server
   sudo systemctl status nginx
   curl http://localhost
   ```

3. Check association executed successfully:
   ```bash
   aws ssm list-association-executions \
     --association-id "WEB-ASSOCIATION-ID" \
     --region eu-central-1
   ```

## Useful Commands Reference

```bash
# Infrastructure Management
make layer-plan LAYER=100-network ENV=sandbox
make layer-apply LAYER=200-iam ENV=sandbox
make layer-outputs LAYER=300-compute ENV=sandbox
make layer-destroy LAYER=150-ssm ENV=sandbox

# SSM Management
make ssm-check                    # List managed instances
make ssm-trigger ENV=sandbox      # Trigger associations manually
make ssm-logs                     # View S3 logs
make ssm-session                  # Connect via Session Manager

# AWS CLI - SSM Commands
aws ssm describe-instance-information --region eu-central-1
aws ssm list-associations --region eu-central-1
aws ssm list-commands --region eu-central-1
aws ssm describe-association --association-id "xxxxx" --region eu-central-1

# AWS CLI - Parameter Store
aws ssm get-parameter --name "/study-ssm-ansible/github/token" --region eu-central-1
aws ssm get-parameters-by-path --path "/study-ssm-ansible/" --region eu-central-1

# AWS CLI - S3 Logs
aws s3 ls s3://study-ssm-ansible-logs-862378407079/associations/ --recursive
aws s3 cp s3://study-ssm-ansible-logs-862378407079/associations/common/xxxxx/stdout -
```

## Cost Monitoring

Monitor your AWS costs for this study project:

```bash
# Check current month costs (estimated)
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --region us-east-1

# Expected monthly cost: $30-50
# - EC2 instances: ~$30-40
# - S3 storage: <$1
# - SSM: Free
# - Parameter Store: Free
```

**Remember**: Destroy resources when not actively studying to avoid unnecessary costs!

---

## Summary Checklist

- [ ] GitHub repository pushed with Ansible playbooks
- [ ] GitHub PAT generated and stored in Parameter Store
- [ ] Layer 100-network deployed
- [ ] Layer 200-iam deployed
- [ ] Layer 300-compute deployed (5 instances)
- [ ] Instances registered with SSM (all Online)
- [ ] Layer 150-ssm deployed (associations created)
- [ ] Initial configuration triggered manually
- [ ] Web servers responding to HTTP requests
- [ ] App servers running Flask application
- [ ] Bastion host accessible via Session Manager
- [ ] Scheduled associations executing every 30 minutes
- [ ] Configuration drift tested and verified

**Project Status**: ✅ Fully deployed and operational

**Next Steps**: Study SSM behavior, test drift restoration, experiment with playbook updates

---

**Last Updated**: 2026-01-04
**Environment**: sandbox-ilionx-amf (862378407079)
**Region**: eu-central-1
