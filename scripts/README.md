# Validation Scripts

Standalone shell scripts for validating SSM + Ansible deployment using AWS CLI.

## Quick Start

### Run Full Validation

```bash
# Comprehensive validation of entire deployment
./scripts/validate-deployment.sh --full
```

### Run Quick Validation

```bash
# Quick check of critical infrastructure only
./scripts/validate-deployment.sh --quick
```

## Individual Scripts

### Infrastructure Validation

#### 1. SSM Fleet Manager
**Script**: `check-ssm-fleet.sh`

Validates all EC2 instances are registered with SSM and online.

```bash
./scripts/check-ssm-fleet.sh
```

**Checks**:
- Instance count (expected: 5)
- SSM registration status (Online/ConnectionLost/Inactive)
- Instance tags (Role, Environment)
- Platform and agent versions

**Exit codes**:
- `0` = All instances online
- `1` = Some instances offline or missing

---

#### 2. SSM State Manager Associations
**Script**: `check-ssm-associations.sh`

Validates SSM associations are configured and executing.

```bash
./scripts/check-ssm-associations.sh
```

**Checks**:
- Association count (expected: 4)
- Association status (Success/Failed/InProgress)
- Execution history
- Expected associations present (common, web, app, bastion)

**Exit codes**:
- `0` = All associations healthy
- `1` = Missing associations or failed executions

---

#### 3. Parameter Store
**Script**: `check-parameter-store.sh`

Validates all required parameters exist in Parameter Store.

```bash
./scripts/check-parameter-store.sh
```

**Checks**:
- GitHub token (`/study-ssm-ansible/github/token`)
- App parameters (database_url, secret_key)
- Nginx parameters (worker_processes)
- Global parameters (environment)

**Exit codes**:
- `0` = All parameters present
- `1` = Missing parameters

---

#### 4. S3 Log Bucket
**Script**: `check-s3-logs.sh [association-type]`

Validates S3 bucket and association logs.

```bash
# Check all association logs
./scripts/check-s3-logs.sh all

# Check specific association
./scripts/check-s3-logs.sh web
./scripts/check-s3-logs.sh app
./scripts/check-s3-logs.sh common
./scripts/check-s3-logs.sh bastion
```

**Checks**:
- S3 bucket exists
- Lifecycle policy configured
- Association log files present
- Log content preview

**Exit codes**:
- `0` = Logs present and accessible
- `0` (warning) = No logs yet (normal if just deployed)

---

### Application Testing

#### 5. Web Servers (Nginx)
**Script**: `test-web-servers.sh`

Tests web server HTTP connectivity and content.

```bash
./scripts/test-web-servers.sh
```

**Checks**:
- Finds web server instances by Role=web tag
- HTTP connectivity (port 80)
- HTTP status code (expect 200)
- Response content validation
- Server header
- Response time

**Exit codes**:
- `0` = All web servers responding
- `1` = Some web servers not responding

---

#### 6. Application Servers (Flask)
**Script**: `test-app-servers.sh`

Tests Flask application via SSM Session Manager.

```bash
./scripts/test-app-servers.sh
```

**Checks**:
- Finds app server instances by Role=app tag
- SSM registration status
- Flask systemd service status
- Health endpoint response (`http://localhost:5000/health`)
- Recent Flask logs

**Exit codes**:
- `0` = All Flask apps responding
- `1` = Some Flask apps not responding

---

### Utilities

#### 7. Upload GitHub Token
**Script**: `upload-github-token.sh [token]`

Uploads GitHub Personal Access Token to Parameter Store.

```bash
# Interactive prompt
./scripts/upload-github-token.sh

# Non-interactive
./scripts/upload-github-token.sh ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Features**:
- Secure input (hidden)
- Token format validation
- Overwrite protection (prompts if exists)
- Verification after upload

---

## Usage Examples

### Complete Deployment Validation

```bash
# After deploying all Terraform layers
./scripts/validate-deployment.sh --full
```

### Pre-Deployment Checks

```bash
# Before deploying 150-ssm layer
./scripts/check-ssm-fleet.sh          # Ensure instances are registered
./scripts/check-parameter-store.sh    # Verify parameters exist
```

### Post-Deployment Checks

```bash
# After deploying 150-ssm layer
./scripts/check-ssm-associations.sh   # Verify associations created
./scripts/check-s3-logs.sh all        # Check logs are being written
```

### Application Validation

```bash
# After associations execute (wait 30 min or trigger manually)
./scripts/test-web-servers.sh         # Test Nginx
./scripts/test-app-servers.sh         # Test Flask
```

### Troubleshooting

```bash
# Debug SSM issues
./scripts/check-ssm-fleet.sh
./scripts/check-ssm-associations.sh
./scripts/check-s3-logs.sh common     # View most recent logs

# Debug application issues
./scripts/test-web-servers.sh
./scripts/test-app-servers.sh
```

## Environment Variables

All scripts support these environment variables:

```bash
# Set AWS region (default: eu-central-1)
export AWS_REGION=eu-central-1

# Set AWS account ID (default: 862378407079)
export AWS_ACCOUNT_ID=862378407079

# Set environment (default: sandbox)
export ENVIRONMENT=sandbox

# Run validation
./scripts/validate-deployment.sh --full
```

## Exit Codes

All scripts follow standard exit code conventions:

- `0` = Success / All checks passed
- `1` = Failure / Some checks failed
- `2` = Script error (missing dependencies, invalid arguments)

## Requirements

### AWS CLI
```bash
# Install AWS CLI
brew install awscli  # macOS
# or
apt-get install awscli  # Linux

# Verify
aws --version
```

### jq (JSON processor)
```bash
# Install jq
brew install jq  # macOS
# or
apt-get install jq  # Linux

# Verify
jq --version
```

### curl (for web server testing)
```bash
# Usually pre-installed
curl --version
```

## Troubleshooting

### Script: Permission Denied

```bash
chmod +x scripts/*.sh
```

### Script: AWS CLI not found

```bash
which aws
# If not found, install AWS CLI
```

### Script: jq command not found

```bash
which jq
# If not found, install jq
```

### Script: Timeout connecting to instances

- Check security groups allow required ports
- Verify instances are in public subnets (for web servers)
- Check SSM registration status

### Script: No instances found

- Verify EC2 instances are running
- Check instances have correct tags (Role=web/app/bastion)
- Verify AWS region is correct

## Integration with Makefile

These scripts complement the Makefile targets:

```bash
# Makefile SSM commands
make ssm-check              # Similar to check-ssm-fleet.sh
make ssm-trigger ENV=sandbox # Trigger associations
make ssm-logs               # View S3 logs
make ssm-session            # Connect to instance

# Validation scripts
./scripts/validate-deployment.sh --full  # Comprehensive validation
```

## CI/CD Integration

Scripts are designed for automation:

```bash
#!/bin/bash
set -e

# Deploy infrastructure
make layer-apply LAYER=100-network ENV=sandbox
make layer-apply LAYER=200-iam ENV=sandbox
make layer-apply LAYER=300-compute ENV=sandbox

# Wait for SSM registration
sleep 120

# Validate
./scripts/check-ssm-fleet.sh || exit 1
./scripts/check-parameter-store.sh || exit 1

# Deploy SSM
make layer-apply LAYER=150-ssm ENV=sandbox

# Validate
./scripts/validate-deployment.sh --full || exit 1
```

## Output Formats

All scripts use colored output for readability:

- 🔵 **Blue**: Informational messages
- 🟢 **Green**: Success / Passed checks
- 🟡 **Yellow**: Warnings / Non-critical issues
- 🔴 **Red**: Errors / Failed checks

## Support

For issues or questions:

1. Check troubleshooting section in deployment guide:
   `./references/steps-after-deploy-terraform-for-ssm-ansible.md`

2. Review SSM concepts:
   `./references/SSM_CONCEPTS.md`

3. Check validation script source code (well-commented)

---

**Last Updated**: 2026-01-04
**Maintainer**: Dennis Vriend
