# AWS Systems Manager Concepts

This document provides a comprehensive overview of AWS Systems Manager (SSM) concepts, specifically focused on configuration management with Ansible integration.

## Table of Contents

1. [SSM Agent](#ssm-agent)
2. [SSM State Manager](#ssm-state-manager)
3. [SSM Associations](#ssm-associations)
4. [SSM Parameter Store](#ssm-parameter-store)
5. [SSM Documents](#ssm-documents)
6. [Pull Model vs Push Model](#pull-model-vs-push-model)
7. [Integration with Ansible](#integration-with-ansible)
8. [Scaling Patterns](#scaling-patterns)

---

## SSM Agent

### What is SSM Agent?

The Amazon SSM Agent is software installed on EC2 instances, on-premises servers, or virtual machines (VMs). The agent processes requests from the Systems Manager service and executes them on the machine.

### Key Characteristics

| Feature | Description |
|---------|-------------|
| **Pre-installed** | Comes pre-installed on Amazon Linux 2023, Amazon Linux 2, and Ubuntu Server AMIs |
| **Polling Mechanism** | Polls the SSM service every 5 minutes for pending commands or associations |
| **No Inbound Ports** | Requires only outbound HTTPS (port 443) to AWS API endpoints |
| **Local Execution** | Executes commands directly on the instance, no SSH required |

### How SSM Agent Works

```
┌─────────────────────────────────────────────────────────────────┐
│                     EC2 Instance                                 │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              SSM Agent (runs as systemd service)          │  │
│  │                                                            │  │
│  │  1. Polls SSM service every 5 minutes                     │  │
│  │  2. Downloads pending commands/associations               │  │
│  │  3. Executes commands locally                             │  │
│  │  4. Uploads output/results to SSM service                 │  │
│  │  5. Updates instance status                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└────────────┬─────────────────────────────────────────────────────┘
             │
             │ HTTPS (443)
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   AWS Systems Manager Service                    │
│                                                                  │
│  - Queues commands for managed instances                         │
│  - Stores association schedules                                   │
│  - Manages parameter store                                        │
│  - Collects and stores execution results                          │
└─────────────────────────────────────────────────────────────────┘
```

### SSM Agent Status Management

The agent maintains the following statuses visible in the SSM Console:

| Status | Description | Action Required |
|--------|-------------|-----------------|
| **Online** | Agent is actively polling and responsive | None |
| **Connection Lost** | Agent hasn't polled within expected time | Check internet connectivity, security groups |
| **Inactive** | Agent not running or not installed | Start/reinstall agent |
| **Registering** | Initial registration in progress | Wait a few minutes |

### Managing SSM Agent

```bash
# Check agent status
sudo systemctl status amazon-ssm-agent

# Restart agent
sudo systemctl restart amazon-ssm-agent

# View agent logs
sudo tail -f /var/log/amazon/ssm/amazon-ssm-agent.log

# Check agent version
sudo amazon-ssm-agent -version
```

---

## SSM State Manager

### What is State Manager?

AWS Systems Manager State Manager is a capability that provides automated configuration management for your managed instances. It ensures your instances maintain a defined state configuration without requiring SSH access or custom scripts.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Desired State** | The configuration you want your instances to have |
| **Idempotency** | Operations can be applied multiple times safely without side effects |
| **Schedule-Based Execution** | Automatic enforcement at defined intervals (cron or rate expressions) |
| **Compliance Reporting** | Track which instances are compliant with your configuration standards |
| **Drift Detection** | Automatically detect and remediate configuration changes |

### State Manager Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    SSM State Manager                             │
│                                                                  │
│  1. Define Association                                           │
│     - Document (AWS-ApplyAnsiblePlaybooks)                       │
│     - Target (tags, instance IDs)                                │
│     - Parameters (playbook path, variables)                      │
│     - Schedule (rate(10 minutes), cron(...))                     │
│                                                                  │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ Schedule Trigger
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Target Selection                               │
│                                                                  │
│  Query instances by tags:                                        │
│  - Environment: sandbox                                          │
│  - Role: web/app/bastion                                         │
│  - Any custom tag combination                                    │
│                                                                  │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ For each matched instance
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Execution Phase                               │
│                                                                  │
│  1. SSM Agent on instance receives association request           │
│  2. Downloads document and parameters                           │
│  3. Executes Ansible playbook locally                           │
│  4. Captures output and exit status                             │
│  5. Uploads results to S3/CloudWatch (optional)                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Schedule Expressions

State Manager supports two types of schedule expressions:

#### Rate Expressions
```bash
# Run every N minutes/hours/days
rate(10 minutes)    # Every 10 minutes
rate(1 hour)        # Every hour
rate(1 day)         # Every day
```

#### Cron Expressions
```bash
# Run at specific times
cron(0 2 * * ? *)        # Daily at 2:00 AM
cron(0/15 * * * ? *)     # Every 15 minutes
cron(0 10 ? * MON-FRI *) # Weekdays at 10:00 AM
```

### Compliance and Drift Detection

State Manager automatically tracks compliance status:

| Compliance Status | Description |
|-------------------|-------------|
| **COMPLIANT** | Association executed successfully |
| **NON-COMPLIANT** | Association failed or hasn't run recently |
| **NOT APPLICABLE** | Instance not targeted by association |

```bash
# View compliance status
aws ssm list-compliance-summaries --filters Key=ComplianceType,Values=Association

# Get detailed compliance results
aws ssm list-compliance-items --resource-id i-1234567890abcdef0 --resource-type ManagedInstance
```

---

## SSM Associations

### What are Associations?

An association is a binding between a document and a set of targets, defining when and how the document should be executed. Associations are the core mechanism for automated configuration management in State Manager.

### Association Components

| Component | Description | Example |
|-----------|-------------|---------|
| **Name** | The SSM document to execute | `AWS-ApplyAnsiblePlaybooks` |
| **Association Name** | Human-readable identifier | `common-configuration` |
| **Targets** | Which instances receive the association | `tag:Environment:sandbox` |
| **Parameters** | Document-specific configuration | Playbook file path, variables |
| **Schedule** | When to execute | `rate(10 minutes)` |
| **Output Location** | Where to store execution logs | S3 bucket prefix |
| **Compliance Severity** | Importance level | `HIGH`, `MEDIUM`, `LOW` |

### Targeting Patterns

#### Tag-Based Targeting

```bash
# Single tag
Key=tag:Environment,Values=sandbox

# Multiple tag values (OR logic)
Key=tag:Role,Values=web,app,bastion

# Multiple tags (AND logic - separate targets)
Target 1: Key=tag:Environment,Values=sandbox
Target 2: Key=tag:Role,Values=web
```

#### Instance ID Targeting

```bash
# Specific instances
Key=InstanceIds,Values=i-1234567890abcdef0,i-0987654321fedcba0
```

#### Resource Group Targeting

```bash
# By resource group
Key=ResourceGroup,Values=ssm-managed-instances
```

### Association Dependencies

You can sequence associations to ensure execution order:

```
Common Configuration (no dependencies)
         │
         ├─► Web Server Configuration (depends on: common)
         │
         ├─► App Server Configuration (depends on: common)
         │
         └─► Bastion Configuration (depends on: common)
```

```hcl
resource "aws_ssm_association" "common" {
  name = "AWS-ApplyAnsiblePlaybooks"
  # ... configuration
}

resource "aws_ssm_association" "web" {
  name             = "AWS-ApplyAnsiblePlaybooks"
  depends_on       = [aws_ssm_association.common]
  # ... configuration
}
```

### Output to S3

Configure associations to write execution logs to S3:

```hcl
output_location {
  s3_bucket_name     = aws_s3_bucket.ssm_logs.id
  s3_key_prefix      = "associations/web/"
  s3_region          = var.aws_region
}
```

Log structure:
```
s3://study-ssm-ansible-logs-862378407079/associations/
├── common/
│   ├── i-1234567890abcdef0/
│   │   └── 2024-01-04/10-30-00/ansible-playbook.log
│   └── i-0987654321fedcba0/
│       └── 2024-01-04/10-30-05/ansible-playbook.log
└── web/
    └── ...
```

### Monitoring Association Executions

```bash
# List recent executions
aws ssm list-association-executions --association-id <association-id>

# Get execution details
aws ssm describe-association-execution-targets \
  --association-id <association-id> \
  --execution-id <execution-id>

# View execution output
aws ssm get-automation-execution --automation-execution-id <execution-id>
```

---

## SSM Parameter Store

### What is Parameter Store?

AWS Systems Manager Parameter Store provides a centralized, secure storage for configuration data and secrets. It offers version tracking, encryption, and access control through IAM policies.

### Parameter Types

| Type | Description | Use Case | Example |
|------|-------------|----------|---------|
| **String** | Plain text | Configuration values | `worker_processes: 2` |
| **StringList** | Comma-separated list | Multiple values | `servers: server1,server2,server3` |
| **SecureString** | KMS-encrypted | Secrets, passwords | `database_password: ****` |

### Hierarchical Organization

Use hierarchical naming for organization:

```
/study-ssm-ansible/
├── global/
│   └── environment
├── app/
│   ├── database_url
│   └── secret_key
└── nginx/
    └── worker_processes
```

### Best Practices

| Practice | Description |
|----------|-------------|
| **Use Hierarchies** | Organize parameters by application, environment, component |
| **Secure Sensitive Data** | Always use `SecureString` for secrets |
| **Version Parameters** | Parameter Store automatically versions each update |
| **IAM Least Privilege** | Grant minimum required permissions |
| **KMS Key Management** | Use customer-managed KMS keys for SecureString |

### IAM Permissions

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
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}
```

### Parameter Store Examples

```bash
# Create a String parameter
aws ssm put-parameter \
  --name "/study-ssm-ansible/nginx/worker_processes" \
  --type "String" \
  --value "2"

# Create a SecureString parameter
aws ssm put-parameter \
  --name "/study-ssm-ansible/app/secret_key" \
  --type "SecureString" \
  --value "super-secret-key-here"

# Get a parameter
aws ssm get-parameter \
  --name "/study-ssm-ansible/app/secret_key" \
  --with-decryption

# Get all parameters in a path
aws ssm get-parameters-by-path \
  --path "/study-ssm-ansible/app/" \
  --recursive \
  --with-decryption

# List parameters in a path
aws ssm describe-parameters \
  --parameter-filters "Key=Path,Option=Recursive,Values=/study-ssm-ansible/"
```

### Parameter Store in Ansible

```yaml
# Lookup parameter in Ansible
- name: Retrieve database URL from Parameter Store
  ansible.builtin.set_fact:
    database_url: "{{ lookup('aws_ssm', '/study-ssm-ansible/app/database_url', region='eu-central-1') }}"

- name: Retrieve secret from Parameter Store
  ansible.builtin.set_fact:
    app_secret: "{{ lookup('aws_ssm', '/study-ssm-ansible/app/secret_key', region='eu-central-1', decrypt=true) }}"
```

---

## SSM Documents

### What are SSM Documents?

SSM Documents define the actions that Systems Manager performs on managed instances. Documents are JSON or YAML formatted and can be built-in (provided by AWS) or custom (created by you).

### Document Structure

```yaml
# Example: Custom SSM Document
schemaVersion: '2.2'
description: 'Run Ansible playbook from local source'
parameters:
  PlaybookFile:
    type: StringList
    description: 'Ansible playbook file name'
    default:
      - site.yml
  ExtraVariables:
    type: StringList
    description: 'Extra variables for ansible-playbook'
    default: []
mainSteps:
  - action: 'aws:runShellScript'
    name: 'runAnsiblePlaybook'
    inputs:
      runCommand:
        - 'cd /opt/ansible'
        - 'ansible-playbook {{ PlaybookFile }} --extra-vars "{{ ExtraVariables | join(' ') }}"'
```

### AWS-ApplyAnsiblePlaybooks Document

The `AWS-ApplyAnsiblePlaybooks` document is a built-in document specifically for executing Ansible playbooks via State Manager.

#### Supported Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `SourceType` | StringList | Yes | `GitHub` or `S3` |
| `SourceInfo` | StringList | Yes | JSON with source details |
| `InstallDependencies` | StringList | No | `True` to install Ansible |
| `PlaybookFile` | StringList | Yes | Path to playbook file |
| `ExtraVariables` | StringList | No | Extra variables for playbook |
| `Check` | StringList | No | `True` for dry-run mode |
| `Verbose` | StringList | No | Verbosity level (`-v`, `-vv`, `-vvv`) |

#### SourceInfo Examples

**GitHub Source:**
```json
{
  "owner": "dennisvriend",
  "repository": "study-ssm-ansible",
  "path": "ansible",
  "getOptions": "branch:main",
  "tokenInfo": "{{ssm-secure:/study-ssm-ansible/github/token}}"
}
```

**S3 Source:**
```json
{
  "path": "https://s3.amazonaws.com/my-bucket/ansible/"
}
```

### Creating Custom Documents

```bash
# Create a custom document
aws ssm create-document \
  --name "MyCustomDocument" \
  --document-type "Command" \
  --content file://my-document.yaml

# List documents
aws ssm list-documents --document-filter "key=DocumentType,value=Command"

# Describe document
aws ssm describe-document --name "AWS-ApplyAnsiblePlaybooks"

# Delete document
aws ssm delete-document --name "MyCustomDocument"
```

### Document Versions

SSM automatically versions documents when you update them:

```bash
# List document versions
aws ssm list-document-versions --name "MyCustomDocument"

# Get specific version
aws ssm get-document --name "MyCustomDocument" --document-version "2"
```

---

## Pull Model vs Push Model

### Traditional Ansible (Push Model)

The traditional Ansible architecture uses a push-based model:

```
┌─────────────────────────────────────────────────────────────────┐
│                      Ansible Control Node                        │
│                                                                  │
│  - Inventory file (hosts.ini)                                    │
│  - Playbooks and roles                                           │
│  - Execution orchestrator                                         │
│  - SSH connectivity to all targets                               │
│                                                                  │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ SSH (port 22)
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Target Servers                               │
│                                                                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                 │
│  │  Target 1  │  │  Target 2  │  │  Target N  │                 │
│  │  SSHd :22  │  │  SSHd :22  │  │  SSHd :22  │                 │
│  └────────────┘  └────────────┘  └────────────┘                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Characteristics:**
| Aspect | Description |
|--------|-------------|
| **Control** | Centralized from control node |
| **Network** | Requires SSH access to targets |
| **Firewall** | Inbound port 22 must be open |
| **Scaling** | Limited by control node resources |
| **Execution** | Parallel, but managed centrally |

### SSM + Ansible (Pull Model)

SSM transforms Ansible into a pull-based model:

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Systems Manager                           │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │              SSM State Manager                          │     │
│  │                                                          │     │
│  │  - Stores associations (schedules)                      │     │
│  │  - Targets instances via tags                           │     │
│  │  - Triggers execution on schedule                       │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
└────────────┬─────────────────────────────────────────────────────┘
             │
             │ HTTPS (443) - Outbound only
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Target Servers                               │
│                                                                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                 │
│  │  Target 1  │  │  Target 2  │  │  Target N  │                 │
│  │  SSM Agent │  │  SSM Agent │  │  SSM Agent │                 │
│  │            │  │            │  │            │                 │
│  │  Pulls     │  │  Pulls     │  │  Pulls     │                 │
│  │  playbook  │  │  playbook  │  │  playbook  │                 │
│  │  Executes  │  │  Executes  │  │  Executes  │                 │
│  │  locally   │  │  locally   │  │  locally   │                 │
│  └────────────┘  └────────────┘  └────────────┘                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Characteristics:**
| Aspect | Description |
|--------|-------------|
| **Control** | Distributed - each instance manages itself |
| **Network** | Only outbound HTTPS to AWS API |
| **Firewall** | No inbound ports required |
| **Scaling** | Scales to hundreds of servers easily |
| **Execution** | Distributed, no central bottleneck |

### Comparison Table

| Feature | Push Model (Traditional Ansible) | Pull Model (SSM + Ansible) |
|---------|---------------------------------|----------------------------|
| **SSH Required** | Yes | No |
| **Inbound Ports** | 22, custom ports | None |
| **Network Requirements** | Control node → Target connectivity | Target → AWS API connectivity |
| **Scalability** | Limited by control node | Limited only by AWS service quotas |
| **Scheduling** | Cron jobs, external schedulers | Built-in State Manager schedules |
| **Inventory Management** | Static files, dynamic scripts | AWS tags, resource groups |
| **Execution Logs** | Local on control node | S3, CloudWatch Logs |
| **Compliance Tracking** | Manual | Built-in compliance reporting |
| **Drift Detection** | Manual or external tools | Automatic with State Manager |
| **Best For** | < 100 servers, on-prem, complex networks | > 100 servers, cloud-native, auto-scaling |

### When to Use Each Model

**Use Push Model when:**
- Managing on-premises servers without AWS connectivity
- Need immediate, ad-hoc execution
- Existing investment in Ansible Control Node
- Complex inventory management not tag-based
- Development/testing environments

**Use Pull Model when:**
- Managing cloud infrastructure (AWS, Azure, GCP)
- Scaling to hundreds or thousands of servers
- Auto-scaling groups where instances appear/disappear
- Need built-in compliance and drift detection
- Want to eliminate SSH access entirely
- Require centralized logging and auditing

---

## Integration with Ansible

### How SSM Executes Ansible Playbooks

The integration workflow:

```
┌─────────────────────────────────────────────────────────────────┐
│                    SSM Association Trigger                       │
│                                                                  │
│  Schedule: rate(10 minutes)                                      │
│  Target: tag:Role=web                                            │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ 1. Trigger
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SSM Agent on Instance                         │
│                                                                  │
│  2. Receive association request                                  │
│  3. Download playbook from GitHub/S3                            │
│  4. Install Ansible dependencies (if needed)                    │
│  5. Execute ansible-playbook locally                            │
│                                                                  │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ 6. Execute
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Local Ansible Execution                        │
│                                                                  │
│  ansible-playbook playbooks/web-server.yml \                    │
│    --connection=local \                                          │
│    --extra-vars "SSM=True ansible_python_interpreter=/usr/bin/python3" \ │
│    -v                                                           │
│                                                                  │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ 7. Capture output
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Output to S3/CloudWatch                        │
│                                                                  │
│  Upload execution logs                                           │
│  Update compliance status                                        │
│  Report success/failure                                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Required Ansible Playbook Format

Playbooks executed by SSM **must** follow this format:

```yaml
---
- name: Playbook Name
  hosts: localhost        # REQUIRED: Must be localhost
  connection: local       # REQUIRED: Must be local connection
  become: yes             # REQUIRED: Must escalate privileges

  pre_tasks:
    - name: Display instance metadata
      ansible.builtin.debug:
        msg: "Running on {{ ansible_hostname }}"

  roles:
    - role: my-role

  post_tasks:
    - name: Verify configuration
      ansible.builtin.debug:
        msg: "Configuration completed successfully"
```

### Parameter Store Integration

Ansible can retrieve parameters from SSM Parameter Store during execution:

```yaml
---
- name: Application Configuration
  hosts: localhost
  connection: local
  become: yes

  vars:
    # Lookup parameters at runtime
    database_url: "{{ lookup('aws_ssm', '/study-ssm-ansible/app/database_url', region='eu-central-1') }}"
    app_secret: "{{ lookup('aws_ssm', '/study-ssm-ansible/app/secret_key', region='eu-central-1', decrypt=true) }}"
    nginx_workers: "{{ lookup('aws_ssm', '/study-ssm-ansible/nginx/worker_processes', region='eu-central-1') }}"

  tasks:
    - name: Display retrieved parameters
      ansible.builtin.debug:
        msg:
          - "Database URL: {{ database_url }}"
          - "Nginx workers: {{ nginx_workers }}"

    - name: Create application config file
      ansible.builtin.template:
        src: templates/app-config.j2
        dest: /opt/app/config.yml
        mode: '0640'
```

### Tag-Based Conditionals

Use tags to conditionally execute tasks:

```yaml
---
- name: Role-Specific Configuration
  hosts: localhost
  connection: local
  become: yes

  tasks:
    - name: Check if instance is web server
      ansible.builtin.debug:
        msg: "This is a web server"
      when: "'web' in ansible_facts['ec2_tags']['Role'] | default('')"

    - name: Install web server packages
      ansible.builtin.yum:
        name:
          - nginx
          - httpd
        state: present
      when: "'web' in ansible_facts['ec2_tags']['Role'] | default('')"

    - name: Check if instance is app server
      ansible.builtin.debug:
        msg: "This is an app server"
      when: "'app' in ansible_facts['ec2_tags']['Role'] | default('')"
```

### Error Handling

Implement proper error handling for SSM execution:

```yaml
---
- name: Configuration with Error Handling
  hosts: localhost
  connection: local
  become: yes

  tasks:
    - name: Attempt configuration
      block:
        - name: Install packages
          ansible.builtin.yum:
            name: "{{ item }}"
            state: present
          loop:
            - nginx
            - python3

        - name: Configure service
          ansible.builtin.template:
            src: templates/config.j2
            dest: /etc/myapp/config.yml

        - name: Start service
          ansible.builtin.systemd:
            name: myapp
            state: started
            enabled: yes

      rescue:
        - name: Log failure
          ansible.builtin.debug:
            msg: "Configuration failed, rolling back"

        - name: Rollback configuration
          ansible.builtin.file:
            path: /etc/myapp/config.yml
            state: absent

        - name: Fail playbook
          ansible.builtin.fail:
            msg: "Configuration failed, check logs"

      always:
        - name: Cleanup temp files
          ansible.builtin.file:
            path: /tmp/myapp-temp
            state: absent
```

---

## Scaling Patterns

### Tag Strategy for Scale

Effective tag hierarchies enable sophisticated targeting patterns:

| Tag Dimension | Purpose | Example Values |
|---------------|---------|----------------|
| **Environment** | Separate deployment environments | `dev`, `test`, `staging`, `prod` |
| **Role** | Define server function | `web`, `app`, `db`, `cache`, `bastion` |
| **Stack** | Group related microservices | `frontend`, `backend-api`, `payment-service` |
| **AZ** | Availability zone placement | `eu-central-1a`, `eu-central-1b` |
| **Team** | Ownership for access control | `platform`, `product`, `data` |

**Example Tag Set:**
```bash
# Web server in production
Environment=prod
Role=web
Stack=frontend
AZ=eu-central-1a
Team=platform

# Database server in production
Environment=prod
Role=db
Stack=payment-service
AZ=eu-central-1b
Team=data
```

### Multi-Dimensional Targeting

Combine tags for precise targeting:

```hcl
# Target all production web servers
resource "aws_ssm_association" "prod_web" {
  name       = "AWS-ApplyAnsiblePlaybooks"
  targets {
    key    = "tag:Environment"
    values = ["prod"]
  }
  targets {
    key    = "tag:Role"
    values = ["web"]
  }
  # Result: Only instances with BOTH tags match
}

# Target multiple roles in production
resource "aws_ssm_association" "prod_tier" {
  name       = "AWS-ApplyAnsiblePlaybooks"
  targets {
    key    = "tag:Environment"
    values = ["prod"]
  }
  targets {
    key    = "tag:Role"
    values = ["web", "app", "cache"]
  }
  # Result: Production AND (web OR app OR cache)
}
```

### Rate Controls

Prevent overwhelming services or causing outages:

```hcl
resource "aws_ssm_association" "rolling_update" {
  name = "AWS-ApplyAnsiblePlaybooks"

  targets {
    key    = "tag:Environment"
    values = ["prod"]
  }

  # Rate control parameters
  max_concurrency = "10%"    # Execute on 10% of targets at once
  max_errors      = "5%"     # Stop if 5% of executions fail

  # For 100 web servers:
  # - First 10 servers execute
  # - Wait for completion
  # - Next 10 servers execute
  # - Continue until all done
  # - Stop immediately if 5 failures occur
}
```

**Rate Control Strategies:**

| Strategy | Max Concurrency | Max Errors | Use Case |
|----------|-----------------|------------|----------|
| **Conservative** | `5%` | `1%` | Critical production services |
| **Balanced** | `10%` | `5%` | Standard production deployments |
| **Aggressive** | `25%` | `10%` | Development/testing environments |
| **Fixed Number** | `50` | `5` | Large fleet with known capacity |

### Canary Deployments

Test configuration changes on a subset first:

```hcl
# Canary association - runs first
resource "aws_ssm_association" "canary" {
  name             = "AWS-ApplyAnsiblePlaybooks"
  association_name = "nginx-update-canary"
  schedule_expression = "cron(0 2 * * ? *)"  # Daily at 2 AM

  targets {
    key    = "tag:Environment"
    values = ["prod"]
  }
  targets {
    key    = "tag:Role"
    values = ["web"]
  }
  targets {
    key    = "tag:Canary"
    values = ["true"]
  }

  # Apply new nginx version
  parameters {
    name  = "ExtraVariables"
    values = ["nginx_version=1.25.3"]
  }
}

# Production association - runs after canary validates
resource "aws_ssm_association" "production" {
  name             = "AWS-ApplyAnsiblePlaybooks"
  association_name = "nginx-update-production"
  schedule_expression = "cron(30 2 * * ? *)"  # 30 min after canary

  targets {
    key    = "tag:Environment"
    values = ["prod"]
  }
  targets {
    key    = "tag:Role"
    values = ["web"]
  }

  depends_on = [aws_ssm_association.canary]

  # Apply new nginx version
  parameters {
    name  = "ExtraVariables"
    values = ["nginx_version=1.25.3"]
  }
}
```

### Auto Scaling Integration

Automatically configure new instances:

```hcl
resource "aws_launch_template" "web_servers" {
  name_prefix   = "web-server-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "web-server"
      Environment = "prod"
      Role        = "web"
      Stack       = "frontend"
      ManagedBy   = "SSM"
    }
  }
}

# Existing association automatically targets new instances
resource "aws_ssm_association" "web_config" {
  name = "AWS-ApplyAnsiblePlaybooks"

  targets {
    key    = "tag:Environment"
    values = ["prod"]
  }
  targets {
    key    = "tag:Role"
    values = ["web"]
  }

  # No changes needed - new instances automatically get configured!
}
```

### Parameter Store Hierarchy at Scale

Organize parameters for large environments:

```
/company-name/
├── global/
│   ├── dns_zone
│   ├── certificate_arn
│   └── backup_bucket
├── envs/
│   ├── prod/
│   │   ├── database_endpoint
│   │   └── redis_endpoint
│   └── dev/
│       ├── database_endpoint
│       └── redis_endpoint
└── apps/
    ├── frontend/
    │   ├── nginx_workers
    │   └── cache_enabled
    └── payment-service/
        ├── api_key
        └── webhook_url
```

**Retrieving Hierarchical Parameters:**

```yaml
# Get all parameters for an app
- name: Get all frontend parameters
  ansible.builtin.set_fact:
    frontend_params: "{{ lookup('aws_ssm', '/company-name/apps/frontend/', region='eu-central-1', recursive=true, with_decryption=true) }}"

# Get environment-specific parameters
- name: Get production database parameters
  ansible.builtin.set_fact:
    db_params: "{{ lookup('aws_ssm', '/company-name/envs/prod/', region='eu-central-1', recursive=true, with_decryption=true) }}"
```

### Real-World Example: 500 Web Servers

```hcl
# Association configuration for 500 web servers
resource "aws_ssm_association" "web_rolling_update" {
  name             = "AWS-ApplyAnsiblePlaybooks"
  association_name = "web-rolling-update"
  schedule_expression = "rate(30 minutes)"

  # Target all 500 web servers across 3 AZs
  targets {
    key    = "tag:Environment"
    values = ["prod"]
  }
  targets {
    key    = "tag:Role"
    values = ["web"]
  }

  # Conservative rate control for stability
  max_concurrency = "10%"  # 50 servers at a time
  max_errors      = "2%"   # Stop if 10 servers fail

  # Association parameters
  parameters {
    name  = "SourceType"
    values = ["GitHub"]
  }
  parameters {
    name  = "SourceInfo"
    values = ["{\"owner\":\"mycompany\",\"repository\":\"infra-ansible\",\"path\":\"playbooks\",\"getOptions\":\"branch:main\",\"tokenInfo\":\"{{ssm-secure:/company/github/token}}\"}"]
  }
  parameters {
    name  = "InstallDependencies"
    values = ["True"]
  }
  parameters {
    name  = "PlaybookFile"
    values = ["web-rolling-update.yml"]
  }
  parameters {
    name  = "ExtraVariables"
    values = ["maintenance_window=true"]
  }
  parameters {
    name  = "Verbose"
    values = ["-v"]
  }

  # Output to S3 for audit
  output_location {
    s3_bucket_name = aws_s3_bucket.ssm_logs.id
    s3_key_prefix  = "associations/web/"
    s3_region      = var.aws_region
  }

  # Compliance severity
  compliance_severity = "HIGH"

  # Timeout for each execution
  sync_compliance = "AUTO"

  # Apply only at next maintenance window
  apply_only_at_cron_interval = true
}
```

**Execution Timeline for 500 Servers:**

| Wave | Servers | Duration | Cumulative Time |
|------|---------|----------|-----------------|
| 1 | 50 | ~5 min | 5 min |
| 2 | 50 | ~5 min | 10 min |
| 3 | 50 | ~5 min | 15 min |
| 4 | 50 | ~5 min | 20 min |
| 5 | 50 | ~5 min | 25 min |
| 6 | 50 | ~5 min | 30 min |
| 7 | 50 | ~5 min | 35 min |
| 8 | 50 | ~5 min | 40 min |
| 9 | 50 | ~5 min | 45 min |
| 10 | 50 | ~5 min | 50 min |

**Total Time:** ~50 minutes to update all 500 web servers with zero downtime.

### Monitoring at Scale

```bash
# Monitor association progress across fleet
watch -n 10 'aws ssm list-association-executions \
  --association-id assoc-0123456789abcdef0 \
  --query "sort_by(AssociationExecutions, &CreateTime)[::-1][:5]" \
  --output table'

# Check compliance status
aws ssm list-compliance-summaries \
  --filters Key=ComplianceType,Values=Association \
  --query "ComplianceSummaryItems[?ComplianceType=='Association'].{Status:ComplianceStatus,Count:CompliantSummary.CompliantCount}" \
  --output table

# View failed executions
aws ssm describe-association-execution-targets \
  --association-id assoc-0123456789abcdef0 \
  --execution-id 12345678-1234-1234-1234-123456789012 \
  --query "Targets[?Status=='Failed']" \
  --output table
```

### Scaling Best Practices

| Practice | Description |
|----------|-------------|
| **Tag Consistency** | Enforce consistent tagging across all resources |
| **Rate Controls** | Always use concurrency and error limits |
| **Canary Testing** | Test on subset before fleet-wide rollout |
| **Scheduled Maintenance** | Use maintenance windows for disruptive changes |
| **Compliance Monitoring** | Set up CloudWatch alarms on compliance status |
| **Log Aggregation** | Centralize logs in S3 or CloudWatch Logs |
| **Rollback Plans** | Keep previous playbook versions for quick rollback |
| **Parameter Versioning** | Leverage Parameter Store versioning for configs |

---

## Summary

AWS Systems Manager provides a powerful platform for configuration management at scale. When combined with Ansible, it offers:

- **Scalability**: Manage hundreds to thousands of servers
- **Security**: No SSH required, encrypted parameter storage
- **Reliability**: Idempotent operations with drift detection
- **Compliance**: Built-in compliance reporting and audit trails
- **Flexibility**: Tag-based targeting and sophisticated scheduling

The pull model architecture eliminates the need for a central control node, making it ideal for cloud-native environments and auto-scaling workloads.

---

## Additional Resources

- [AWS Systems Manager Documentation](https://docs.aws.amazon.com/systems-manager/)
- [SSM State Manager with Ansible](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-state-manager-ansible.html)
- [SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [AWS-ApplyAnsiblePlaybooks Document Reference](https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-ansible-playbook.html)
