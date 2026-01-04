# Design Documentation - SSM + Ansible Study Project

## Architecture Overview

### System Diagram

```
                              Internet
                                 │
                                 │
                    ┌────────────┴────────────┐
                    │   Internet Gateway      │
                    │   (100-network layer)   │
                    └────────────┬────────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
        │                        │                        │
┌───────┴────────┐    ┌──────────┴─────────┐    ┌────────┴────────┐
│  Web Server 1  │    │   Web Server 2     │    │   Bastion       │
│  t3.micro      │    │   t3.micro         │    │   t3.micro      │
│  Role=web      │    │   Role=web         │    │   Role=bastion  │
│  Nginx :80     │    │   Nginx :80        │    │   SSH :22       │
└───────┬────────┘    └──────────┬─────────┘    └────────┬────────┘
        │                        │                        │
        │                        │                        │
        └────────────────────────┼────────────────────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
┌───────┴────────┐    ┌──────────┴─────────┐    ┌────────┴────────┐
│  App Server 1  │    │   App Server 2     │    │                 │
│  t3.small      │    │   t3.small         │    │   SSM Managed   │
│  Role=app      │    │   Role=app         │    │   Instances     │
│  Flask :5000   │    │   Flask :5000      │    │                 │
└────────────────┘    └────────────────────┘    └─────────────────┘
         │                      │
         └──────────┬───────────┘
                    │
        ┌───────────┴────────────┐
        │                        │
┌───────┴────────┐    ┌──────────┴─────────┐
│ SSM Agent      │    │ SSM State Manager  │
│ (Local on      │    │ (150-ssm layer)    │
│  each instance)│    │                    │
└───────┬────────┘    └──────────┬─────────┘
        │                        │
        │                        │
        │              ┌─────────┴─────────┐
        │              │                   │
        │              │                   │
┌───────┴────────┐    │   ┌──────────────┴──────────┐
│ Ansible        │    │   │ SSM Parameter Store      │
│ (Playbook      │◄───┘   │ /study-ssm-ansible/*     │
│  Execution)    │        └──────────┬───────────────┘
└────────────────┘                   │
                                     │
                        ┌────────────┴───────────┐
                        │                        │
                 ┌──────┴──────┐         ┌───────┴────────┐
                 │ GitHub Repo │         │ S3 Log Bucket  │
                 │ (Playbooks) │         │ (7-day retain) │
                 └─────────────┘         └────────────────┘
```

### Component Overview

| Component | Quantity | Type | Purpose |
|-----------|----------|------|---------|
| Web Servers | 2 | EC2 t3.micro | Nginx serving static content |
| App Servers | 2 | EC2 t3.small | Flask API with systemd service |
| Bastion | 1 | EC2 t3.micro | SSH access for debugging |
| VPC | 1 | 10.10.0.0/16 | Network isolation |
| Public Subnets | 2 | /24 each | Multi-AZ distribution |
| SSM Associations | 4 | State Manager | Configuration enforcement |
| SSM Parameters | 5 | Parameter Store | Configuration and secrets |

### SSM State Manager Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SSM State Manager                               │
│                    (150-ssm layer)                                      │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ 1. Schedule Trigger (rate 10 minutes)
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      Target Selection                                   │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Tag Query: Environment=sandbox AND Role=web/app/bastion          │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ 2. For each matched instance
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      SSM Agent (On Instance)                            │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ 1. Polls SSM Service for pending associations                    │  │
│  │ 2. Downloads Ansible playbook from GitHub                        │  │
│  │ 3. Installs dependencies (ansible, python3)                      │  │
│  │ 4. Executes: ansible-playbook localhost -c local                 │  │
│  │ 5. Uploads output to S3                                          │  │
│  │ 6. Reports status back to SSM                                    │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ 3. Output logging
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      S3 Log Bucket                                      │
│              study-ssm-ansible-logs-{account_id}                        │
│  ├── associations/common/                                              │
│  ├── associations/web/                                                 │
│  ├── associations/app/                                                 │
│  └── associations/bastion/                                             │
└─────────────────────────────────────────────────────────────────────────┘
```

## Technical Stack

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| **Infrastructure** | OpenTofu | 1.9.0 | IaC, state management |
| **Provider** | AWS | 6.27.0 | AWS resource provisioning |
| **OS** | Amazon Linux | 2023 | EC2 instance OS |
| **Configuration** | Ansible | 2.16+ | Configuration management |
| **Python** | Python | 3.11 | Flask application runtime |
| **Web Server** | Nginx | Latest (AL2023) | Static content serving |
| **Application** | Flask | 3.0+ | REST API framework |
| **WSGI Server** | Gunicorn | 21.0+ | Production Python server |
| **Management** | AWS SSM | - | State Manager, Parameter Store |
| **Logging** | CloudWatch | - | Metrics and logs |
| **VCS** | Git | - | Version control for playbooks |
| **Region** | AWS eu-central-1 | - | Frankfurt region |

### Ansible Technical Details

**Execution Method**:
- `hosts: localhost` (SSM executes locally on each instance)
- `connection: local` (no SSH required)
- `become: yes` (sudo for system changes)

**Module Requirements**:
- `ansible.builtin` prefix for all core modules
- AWS SSM lookup plugin for Parameter Store access
- Jinja2 templating for configuration files

**Role Structure**:
```
roles/
├── common/          # Base configuration (packages, users, security)
├── nginx/           # Web server configuration
├── flask-app/       # Python application deployment
└── monitoring/      # CloudWatch agent setup
```

## Design Decisions

### Why 5 Instances?

**Rationale**: Demonstrates multi-target tag-based association patterns

- **2 Web Servers**: Shows horizontal scaling and load distribution across AZs
- **2 App Servers**: Demonstrates three-tier architecture with dedicated app tier
- **1 Bastion**: Provides secure SSH access for debugging without exposing application servers

**Scaling Implication**: Tag-based targeting works identically for 5 or 500 instances

### Why Flask Application?

**Rationale**: Realistic application deployment patterns

- **Python virtualenv**: Demonstrates isolated Python environment management
- **Systemd service**: Production-grade service lifecycle management
- **Gunicorn**: Industry-standard WSGI server for Python applications
- **Parameter Store integration**: Secure secret retrieval patterns

**Alternative Considered**: Simple static file deployment
**Rejection**: Does not demonstrate systemd, virtualenv, or runtime configuration

### Why 150-ssm Layer?

**Rationale**: Clean separation of concerns in layered architecture

- **Position**: Between 100-network and 200-iam logically, but depends on 300-compute outputs
- **Purpose**: Isolates all SSM-specific resources (associations, parameters, S3 logs)
- **Benefit**: Easy to enable/disable SSM without affecting network or IAM layers
- **Pattern**: Mirrors AWS service boundaries (SSM is a distinct AWS service)

**Alternative Considered**: Merge into 300-compute layer
**Rejection**: Would couple compute resources with management configuration, violating separation of concerns

### Why 10-Minute Schedule?

**Rationale**: Fast iteration for learning and testing

- **Study Context**: Enables rapid feedback when modifying playbooks
- **Drift Detection**: Quick verification of configuration restoration
- **Cost Consideration**: SSM State Manager is free tier

**Production Recommendation**: 30-60 minutes for production workloads

**Rate Expression**: `rate(10 minutes)` (cron-style also supported)

### Why Public Subnets?

**Rationale**: Simplified sandbox setup for learning

- **Cost Savings**: No NAT Gateway (~$32/month per AZ)
- **Simplified Networking**: Direct internet access for SSM Agent
- **Security**: Security groups restrict ingress; instances are not publicly accessible except web servers

**Trade-off**: Production deployments would use private subnets with NAT Gateway or VPC endpoints

**Network Flow**: EC2 instances → IGW → AWS SSM API endpoints (HTTPS)

### Why Manual GitHub PAT?

**Rationale**: Security best practice for secrets management

- **Terraform State**: Avoids storing sensitive tokens in state files
- **Rotation**: Manual control over token lifecycle
- **Audit**: CloudTrail logs parameter access
- **Separation**: Infrastructure (Terraform) vs. secrets (manual)

**Setup Command**:
```bash
aws ssm put-parameter \
  --name "/study-ssm-ansible/github/token" \
  --value "ghp_xxxxxxxxxxxx" \
  --type "SecureString" \
  --region eu-central-1
```

**Reference**: SSM Associations reference `{{ssm-secure:/study-ssm-ansible/github/token}}`

### Why Ansible vs. Other Tools?

**Rationale**: Industry-standard configuration management with AWS integration

- **AWS Native**: SSM Agent includes Ansible runtime
- **Declarative**: Idempotent operations with clear state definition
- **Ecosystem**: Extensive module library and community support
- **Pull Model**: SSM enables Ansible without SSH (traditional limitation)

**Alternatives Considered**:
- **Chef/Puppet**: Heavier weight, require infrastructure
- **Cloud-Init**: One-time execution, no drift remediation
- **User Data Scripts**: Not idempotent, hard to maintain

## Network Architecture

### VPC Configuration

```
VPC CIDR: 10.10.0.0/16
Region: eu-central-1 (Frankfurt)
DNS Support: Enabled
DNS Hostnames: Enabled
```

### Subnet Design

| Subnet | CIDR | AZ | Type | Purpose |
|--------|------|-----|------|---------|
| Public 1 | 10.10.1.0/24 | eu-central-1a | Public | Web-1, App-1, Bastion |
| Public 2 | 10.10.2.0/24 | eu-central-1b | Public | Web-2, App-2 |

**Public Subnet Characteristics**:
- Map public IP on launch: `true`
- Auto-assign IPv6: `false` (IPv4 only)
- Route to Internet Gateway: `0.0.0.0/0`

### Routing

```
Public Route Table:
  10.10.0.0/16 (local) → VPC
  0.0.0.0/0 → Internet Gateway
```

### Security Groups

**Web Server SG** (`ssm-ansible-web-sg`):
```
Ingress:
  HTTP (80)    from 0.0.0.0/0
  HTTPS (443)  from 0.0.0.0/0
  SSH (22)     from Bastion SG

Egress:
  All traffic  to 0.0.0.0/0
```

**App Server SG** (`ssm-ansible-app-sg`):
```
Ingress:
  Flask (5000) from Web SG
  SSH (22)     from Bastion SG

Egress:
  All traffic  to 0.0.0.0/0
```

**Bastion SG** (`ssm-ansible-bastion-sg`):
```
Ingress:
  SSH (22)     from var.allowed_ssh_cidrs (default: 0.0.0.0/0)

Egress:
  All traffic  to 0.0.0.0/0
```

### Network Flow Diagram

```
Internet User
     │
     │ HTTP :80
     ▼
┌─────────────────────────────────────────────────┐
│              Internet Gateway                    │
└─────────────────────────────────────────────────┘
     │
     │
     ▼
┌─────────────────────────────────────────────────┐
│  Web Server 1 (10.10.1.0/24)                    │
│  Security Group: Allow 80, 443 from 0.0.0.0/0   │
│  Nginx serving static content                   │
└─────────────────────────────────────────────────┘
     │
     │ Flask Request :5000
     ▼
┌─────────────────────────────────────────────────┐
│  App Server 1 (10.10.1.0/24)                    │
│  Security Group: Allow 5000 from Web SG only    │
│  Flask API application                          │
└─────────────────────────────────────────────────┘
```

## IAM Permissions

### SSM Instance Role

**Role Name**: `ssm-ansible-ec2-role`

**Trust Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "ec2.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }]
}
```

### Attached Managed Policies

**1. AmazonSSMManagedInstanceCore** (AWS Managed)
- SSM Agent service access
- SSM document execution
- SSM log upload to CloudWatch
- Instance registration

**2. CloudWatchAgentServerPolicy** (AWS Managed)
- Metric collection and upload
- Log streaming to CloudWatch Logs

### Custom Inline Policy

**Policy Name**: `parameter-store-read`

**Purpose**: Allow SSM associations to retrieve configuration parameters

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:eu-central-1:862378407079:parameter/study-ssm-ansible/*"
    },
    {
      "Effect": "Allow",
      "Action": "kms:Decrypt",
      "Resource": "*"
    }
  ]
}
```

**Permissions Breakdown**:
- `ssm:GetParameter`: Retrieve single parameter
- `ssm:GetParameters`: Retrieve multiple parameters
- `ssm:GetParametersByPath`: Retrieve all parameters under path
- `kms:Decrypt`: Decrypt SecureString parameters

### Instance Profile

**Name**: `ssm-ansible-instance-profile`

**Purpose**: Pass IAM role to EC2 instances at launch

**Usage in Terraform**:
```hcl
resource "aws_instance" "web" {
  iam_instance_profile = data.terraform_remote_state.iam.outputs.ssm_ansible_instance_profile_name
  # ...
}
```

### S3 Log Bucket Permissions (Implicit)

The `AmazonSSMManagedInstanceCore` policy includes S3 write permissions for SSM association outputs.

**Bucket**: `study-ssm-ansible-logs-{account_id}`

**Path Pattern**: `associations/{association_name}/{instance_id}/{timestamp}/`

## Tag Strategy

### Standard Tags

| Tag Key | Tag Value | Purpose | Example |
|---------|-----------|---------|---------|
| Name | `ssm-ansible-{role}-{index}` | Instance identification | `ssm-ansible-web-1` |
| Role | `web` / `app` / `bastion` | SSM association targeting | `Role=web` |
| Environment | `sandbox` | Environment isolation | `Environment=sandbox` |
| Stack | `demo` | Application grouping | `Stack=demo` |
| ManagedBy | `SSM-Ansible` | Management identifier | `ManagedBy=SSM-Ansible` |
| AZ | `eu-central-1a` | Availability zone tracking | `AZ=eu-central-1a` |

### SSM Targeting by Tags

**Tag-Based Targeting Examples**:

```hcl
# Target all instances in sandbox environment
resource "aws_ssm_association" "common" {
  targets {
    key    = "tag:Environment"
    values = ["sandbox"]
  }
}

# Target all web servers
resource "aws_ssm_association" "web" {
  targets {
    key    = "tag:Role"
    values = ["web"]
  }
}

# Multi-dimensional targeting (production web servers)
resource "aws_ssm_association" "prod_web" {
  targets {
    key    = "tag:Environment"
    values = ["prod"]
  }
  targets {
    key    = "tag:Role"
    values = ["web"]
  }
}
```

### Scaling to Hundreds of Servers

**Tag Hierarchy for Scale**:

```
study-ssm-ansible/
├── Environment: dev/test/prod
├── Role: web/app/db/cache/bastion
├── Stack: microservice-name
├── Team: team-owning-service
└── AZ: eu-central-1a/b/c
```

**Multi-Dimensional Targeting**:
- Single service: `Environment=prod AND Stack=payment-api`
- All web servers: `Role=web AND Environment=prod`
- Team ownership: `Team=platform AND Environment=*`

### Tag Enforcement

**Terraform Provider Configuration**:
```hcl
provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Project     = "study-ssm-ansible"
      ManagedBy   = "OpenTofu"
      Environment = var.environment
    }
  }
}
```

**Instance-Specific Tags**:
```hcl
resource "aws_instance" "web" {
  tags = {
    Name = "ssm-ansible-web-${count.index + 1}"
    Role = "web"
    AZ   = element(["eu-central-1a", "eu-central-1b"], count.index)
  }
}
```

## Cost Estimates

### EC2 Instances (Monthly)

| Instance | Type | Quantity | vCPU | Memory | Price/hr | Monthly |
|----------|------|----------|------|--------|----------|---------|
| Web Server | t3.micro | 2 | 2 | 1 GiB | $0.0076 | $11.02 |
| App Server | t3.small | 2 | 2 | 2 GiB | $0.0152 | $22.04 |
| Bastion | t3.micro | 1 | 2 | 1 GiB | $0.0076 | $5.51 |
| **Total EC2** | | | | | | **$38.57** |

**Calculation**: Price/hr × 24 hr × 30 days × quantity

### S3 Storage (Monthly)

| Resource | Size | Storage Class | Price/GB | Monthly |
|----------|------|---------------|----------|---------|
| Association Logs | ~100 MB | Standard | $0.023/GB | $0.0023 |
| Lifecycle: 7-day retention | - | - | - | - |
| **Total S3** | | | | **<$0.01** |

### SSM Services

| Service | Usage | Cost |
|---------|-------|------|
| SSM State Manager | Unlimited associations | **Free** |
| SSM Parameter Store | Standard tier (10K+ requests) | **Free** |
| SSM Agent | Pre-installed on AL2023 | **Free** |

### Data Transfer (Estimated)

| Type | Direction | Monthly | Cost |
|------|-----------|---------|------|
| SSM Agent polling | Outbound | ~1 GB | $0.09 |
| Ansible GitHub downloads | Inbound | ~100 MB | Free |
| Association logs to S3 | Outbound | ~50 MB | $0.005 |
| **Total Data Transfer** | | | **~$0.10** |

### Total Cost Summary

| Component | Monthly Cost |
|-----------|--------------|
| EC2 Instances | $38.57 |
| S3 Storage | <$0.01 |
| Data Transfer | $0.10 |
| SSM Services | $0.00 |
| **Total** | **~$39/month** |

### Cost Optimization Strategies

1. **Terminate When Not Studying**: All EC2 instances can be stopped/destroyed
   ```bash
   make destroy-all ENV=sandbox
   ```

2. **Use Instance Schedules**: Auto-start/stop during working hours (saves ~60%)

3. **Switch to Spot Instances**: t3.micro spot can save ~70% (not recommended for stateful learning)

4. **Reduce Instance Counts**: Use 1 web + 1 app server for basic testing (~$20/month)

5. **Region Selection**: eu-central-1 is mid-tier; us-east-1 is cheaper, ap-southeast-1 is more expensive

### Cost Alerts Setup

```bash
# Set budget alert at $50/month
aws budgets create-budget \
  --account-id 862378407079 \
  --budget 'file://budget.json'
```

**budget.json**:
```json
{
  "BudgetName": "ssm-ansible-monthly",
  "BudgetLimit": {
    "Amount": "50",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```
