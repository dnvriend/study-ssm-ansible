# SSM + Ansible Study Project - Task Breakdown

## Project Overview

Implementation of AWS Systems Manager + Ansible integration study project with 5 EC2 instances demonstrating pull-based configuration management at scale.

**Key Deliverables**:
1. Ansible playbooks and roles (mono-repo structure)
2. Terraform infrastructure across 4 layers (100-network, 150-ssm, 200-iam, 300-compute)
3. Reference documentation for learning and troubleshooting

---

## Job 1: Ansible Implementation

**Working Directory**: `/Users/dennisvriend/projects/study-ssm-ansible`
**Branch**: `feature/ansible-playbooks`
**Dependencies**: None (can start immediately)
**Estimated Tasks**: 6

### Task 1.1: Ansible Directory Structure and Configuration

**Prompt for ZAI Worker**:
```
Create the complete Ansible directory structure for the SSM study project:

Directory structure to create:
ansible/
├── playbooks/
├── roles/
│   ├── common/{tasks,templates,handlers}/
│   ├── nginx/{tasks,templates,handlers}/
│   ├── flask-app/{tasks,templates,handlers}/
│   └── monitoring/tasks/
├── group_vars/
└── ansible.cfg

Create these files:

1. ansible/ansible.cfg:
   - Set localhost as default
   - Disable host key checking
   - Enable fact caching
   - Configure for SSM execution (no inventory required)

2. ansible/README.md:
   - Explain the SSM + Ansible integration
   - Document playbook execution via SSM State Manager
   - List all roles and their purposes
   - Provide testing instructions

3. ansible/group_vars/all.yml:
   - Define global variables (environment, aws_region)
   - SSM-specific variables
   - Common package lists

4. ansible/group_vars/tag_Role_web.yml:
   - Nginx worker processes
   - Web server specific variables

5. ansible/group_vars/tag_Role_app.yml:
   - Flask app configuration
   - Python version
   - Application port

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 1)
```

**Success Criteria**:
- All directories created
- Configuration files in place
- README documents structure
- No syntax errors

---

### Task 1.2: Common Role Implementation

**Prompt for ZAI Worker**:
```
Implement the Ansible 'common' role for base configuration applied to all EC2 instances.

Create these files:

1. ansible/roles/common/tasks/main.yml:
   - Include subtasks: packages.yml, users.yml, security.yml
   - Set hostname based on instance tags
   - Configure timezone to UTC
   - Enable SSM Agent

2. ansible/roles/common/tasks/packages.yml:
   - Update all packages (yum update)
   - Install base packages: git, curl, wget, vim, htop, jq, python3, python3-pip
   - Install Amazon CloudWatch agent
   - Install ansible (for local execution)

3. ansible/roles/common/tasks/users.yml:
   - Ensure ec2-user exists
   - Configure sudo access
   - Set shell to bash

4. ansible/roles/common/tasks/security.yml:
   - Configure firewalld (if present)
   - Set SELinux to permissive (for study environment)
   - Configure sysctl security parameters

5. ansible/roles/common/templates/motd.j2:
   - Welcome message showing: hostname, role, environment, managed by SSM
   - Include instance metadata

6. ansible/roles/common/handlers/main.yml:
   - Handler to restart SSM agent
   - Handler to reload sysctl

IMPORTANT:
- Use 'hosts: localhost' and 'connection: local'
- All tasks must be idempotent
- Add proper tags for selective execution
- Include ansible.builtin prefix for all modules

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 1.2)
```

**Success Criteria**:
- All task files created
- Idempotent operations
- Handlers defined
- Templates render correctly

---

### Task 1.3: Nginx Role Implementation

**Prompt for ZAI Worker**:
```
Implement the Ansible 'nginx' role for web server configuration.

Create these files:

1. ansible/roles/nginx/tasks/main.yml:
   - Include subtasks: install.yml, configure.yml
   - Ensure nginx is installed and running
   - Copy custom index.html
   - Enable nginx on boot

2. ansible/roles/nginx/tasks/install.yml:
   - Install nginx package
   - Create required directories
   - Set proper ownership

3. ansible/roles/nginx/tasks/configure.yml:
   - Deploy nginx.conf from template
   - Deploy default site config from template
   - Deploy custom index.html from template
   - Validate nginx configuration
   - Restart nginx if config changed

4. ansible/roles/nginx/templates/nginx.conf.j2:
   - Worker processes from variable (default: 2)
   - Standard nginx configuration
   - Access and error log paths
   - Include sites-enabled

5. ansible/roles/nginx/templates/default-site.j2:
   - Listen on port 80
   - Server name from hostname
   - Root directory /usr/share/nginx/html
   - Access and error logs

6. ansible/roles/nginx/templates/index.html.j2:
   - HTML page showing:
     * Hostname
     * Role: Web Server
     * Environment
     * Deployed via SSM + Ansible
     * Current timestamp
   - Simple CSS styling

7. ansible/roles/nginx/handlers/main.yml:
   - Handler: reload nginx
   - Handler: restart nginx
   - Handler: validate nginx config

IMPORTANT:
- Use ansible.builtin.systemd for service management
- Validate config before restarting
- Use notify for handlers

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 1.2)
Reference Obsidian note: /Users/dennisvriend/projects/obsidian-knowledge-base/reference/aws/ssm-ansible-monitoring-stack-terraform.md (Nginx examples)
```

**Success Criteria**:
- Nginx installs correctly
- Configuration validates
- Service starts and enables
- Index page displays properly

---

### Task 1.4: Flask App Role Implementation

**Prompt for ZAI Worker**:
```
Implement the Ansible 'flask-app' role for Python Flask application deployment.

Create these files:

1. ansible/roles/flask-app/tasks/main.yml:
   - Include subtasks: python.yml, application.yml, systemd.yml
   - Ensure Flask app is deployed and running
   - Enable app service on boot

2. ansible/roles/flask-app/tasks/python.yml:
   - Install Python 3.11 (Amazon Linux 2023)
   - Install pip and virtualenv
   - Create application user: flask-app
   - Create app directory: /opt/flask-app
   - Create virtualenv: /opt/flask-app/venv

3. ansible/roles/flask-app/tasks/application.yml:
   - Deploy app.py from template
   - Deploy requirements.txt from template
   - Install Python dependencies in virtualenv
   - Set proper ownership
   - Retrieve database_url from SSM Parameter Store: /study-ssm-ansible/app/database_url
   - Retrieve secret_key from SSM Parameter Store: /study-ssm-ansible/app/secret_key

4. ansible/roles/flask-app/tasks/systemd.yml:
   - Deploy systemd unit file from template
   - Reload systemd daemon
   - Enable and start flask-app service

5. ansible/roles/flask-app/templates/app.py.j2:
   - Simple Flask application
   - Route /: Returns JSON with hostname, environment, status
   - Route /health: Health check endpoint
   - Route /info: Instance metadata
   - Uses environment variables for config
   - Runs on port 5000

6. ansible/roles/flask-app/templates/requirements.txt.j2:
   - flask>=3.0.0
   - gunicorn>=21.0.0
   - boto3>=1.34.0

7. ansible/roles/flask-app/templates/flask-app.service.j2:
   - Systemd unit file
   - User: flask-app
   - WorkingDirectory: /opt/flask-app
   - ExecStart: /opt/flask-app/venv/bin/gunicorn --bind 0.0.0.0:5000 app:app
   - Environment variables from SSM parameters
   - Restart: always

8. ansible/roles/flask-app/handlers/main.yml:
   - Handler: restart flask-app
   - Handler: reload systemd

IMPORTANT:
- Use AWS SSM Parameter Store lookup plugin for secrets
- Install boto3 for AWS SDK access
- Use gunicorn for production-ready WSGI server
- Proper systemd unit with restart policies

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 1.2)
```

**Success Criteria**:
- Python virtualenv created
- Flask app deploys successfully
- Systemd service runs
- Health endpoint responds

---

### Task 1.5: Monitoring Role Implementation

**Prompt for ZAI Worker**:
```
Implement the Ansible 'monitoring' role for basic CloudWatch metrics.

Create these files:

1. ansible/roles/monitoring/tasks/main.yml:
   - Install CloudWatch agent
   - Deploy CloudWatch agent config
   - Start and enable CloudWatch agent
   - Install and configure node_exporter (optional)

2. ansible/roles/monitoring/templates/cloudwatch-config.json.j2:
   - Collect system metrics (CPU, memory, disk)
   - Collect custom application metrics
   - Log aggregation configuration
   - Namespace: SSM-Ansible-Study
   - Dimensions: Environment, Role, InstanceId

IMPORTANT:
- Use amazon-cloudwatch-agent package
- Configure metrics collection interval: 60 seconds
- Send metrics to eu-central-1 region

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 1.2)
```

**Success Criteria**:
- CloudWatch agent installs
- Metrics publish to CloudWatch
- Configuration validates

---

### Task 1.6: Playbooks Implementation

**Prompt for ZAI Worker**:
```
Create all main Ansible playbooks that will be executed by SSM State Manager.

Create these files:

1. ansible/playbooks/common.yml:
   - Name: "Common Configuration for All Instances"
   - hosts: localhost
   - connection: local
   - become: yes
   - Roles: common
   - Tags: common, base

2. ansible/playbooks/web-server.yml:
   - Name: "Web Server Configuration"
   - hosts: localhost
   - connection: local
   - become: yes
   - Roles: common, nginx, monitoring
   - Tags: web, nginx

3. ansible/playbooks/app-server.yml:
   - Name: "Application Server Configuration"
   - hosts: localhost
   - connection: local
   - become: yes
   - Roles: common, flask-app, monitoring
   - Tags: app, flask

4. ansible/playbooks/bastion.yml:
   - Name: "Bastion Host Configuration"
   - hosts: localhost
   - connection: local
   - become: yes
   - Roles: common, monitoring
   - Additional tasks:
     * Harden SSH configuration
     * Install session recording tools
     * Configure enhanced logging
   - Tags: bastion, security

IMPORTANT:
- All playbooks MUST use 'hosts: localhost' and 'connection: local'
- All playbooks MUST use 'become: yes'
- Include proper error handling
- Add pre_tasks to display instance metadata
- Add post_tasks to verify service status

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 1.2)
```

**Success Criteria**:
- All playbooks created
- Proper role inclusion
- Tags defined
- SSM-compatible format

---

## Job 2: Terraform Infrastructure - Network and IAM

**Working Directory**: `/Users/dennisvriend/projects/study-ssm-ansible`
**Branch**: `feature/terraform-base-layers`
**Dependencies**: None (can run parallel with Job 1)
**Estimated Tasks**: 4

### Task 2.1: Network Layer - VPC and Subnets

**Prompt for ZAI Worker**:
```
Extend the 100-network layer with VPC, subnets, and internet gateway for the SSM study project.

Files to modify/create:

1. layers/100-network/main.tf:
   - VPC: CIDR 10.10.0.0/16, enable DNS hostnames and support
   - Internet Gateway
   - 2 Public Subnets:
     * 10.10.1.0/24 in eu-central-1a
     * 10.10.2.0/24 in eu-central-1b
   - Map public IP on launch: true
   - Public route table with 0.0.0.0/0 -> IGW
   - Route table associations

2. layers/100-network/variables.tf:
   - vpc_cidr (default: "10.10.0.0/16")
   - availability_zones (default: ["eu-central-1a", "eu-central-1b"])
   - public_subnet_cidrs (default: ["10.10.1.0/24", "10.10.2.0/24"])
   - environment (required)
   - aws_region (default: "eu-central-1")
   - aws_account_id (required)

3. layers/100-network/outputs.tf:
   - vpc_id
   - public_subnet_ids (list)
   - internet_gateway_id
   - All security group IDs (from security-groups.tf)

4. layers/100-network/envs/sandbox.tfvars:
   - environment = "sandbox"
   - aws_region = "eu-central-1"
   - aws_account_id = "862378407079"
   - vpc_cidr = "10.10.0.0/16"

5. Update layers/100-network/README.md:
   - Document VPC architecture
   - List all resources
   - Show dependencies (none)
   - Deployment instructions

IMPORTANT:
- Use data source for availability zones
- Follow existing project patterns from other layers
- Include proper tagging (Project, Environment, Layer, ManagedBy)

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 2)
Existing patterns: layers/100-network/provider.tf, layers/100-network/main.tf
```

**Success Criteria**:
- VPC created with correct CIDR
- Subnets in correct AZs
- Internet gateway attached
- Routing configured
- Outputs defined

---

### Task 2.2: Network Layer - Security Groups

**Prompt for ZAI Worker**:
```
Create security groups for the SSM study project in the 100-network layer.

Create new file:

1. layers/100-network/security-groups.tf:

   a. Security Group: web_sg
      - Name: "ssm-ansible-web-sg"
      - Description: "Security group for web servers"
      - Ingress rules:
        * HTTP (80) from 0.0.0.0/0
        * HTTPS (443) from 0.0.0.0/0
        * SSH (22) from bastion_sg only
      - Egress: all traffic to 0.0.0.0/0
      - Tags: Name, Role=web

   b. Security Group: app_sg
      - Name: "ssm-ansible-app-sg"
      - Description: "Security group for app servers"
      - Ingress rules:
        * Flask (5000) from web_sg only
        * SSH (22) from bastion_sg only
      - Egress: all traffic to 0.0.0.0/0
      - Tags: Name, Role=app

   c. Security Group: bastion_sg
      - Name: "ssm-ansible-bastion-sg"
      - Description: "Security group for bastion host"
      - Ingress rules:
        * SSH (22) from var.allowed_ssh_cidrs (variable: default ["0.0.0.0/0"])
      - Egress: all traffic to 0.0.0.0/0
      - Tags: Name, Role=bastion, Management=true

2. Add to layers/100-network/variables.tf:
   - allowed_ssh_cidrs (list, default: ["0.0.0.0/0"], description: "CIDRs allowed to SSH to bastion")

3. Add to layers/100-network/outputs.tf:
   - web_security_group_id
   - app_security_group_id
   - bastion_security_group_id

IMPORTANT:
- Security group rules must reference each other correctly
- Use security_groups (not cidr_blocks) for internal references
- Add descriptions to all rules
- Bastion SG should be restrictive (var.allowed_ssh_cidrs)

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 2.2)
```

**Success Criteria**:
- All security groups created
- Correct ingress/egress rules
- Cross-references working
- Outputs defined

---

### Task 2.3: IAM Layer - SSM Roles and Policies

**Prompt for ZAI Worker**:
```
Extend the 200-iam layer with IAM roles and policies for SSM + Ansible integration.

Create new file:

1. layers/200-iam/ssm-roles.tf:

   a. IAM Role: ssm_ansible_role
      - Name: "ssm-ansible-ec2-role"
      - Description: "IAM role for EC2 instances managed by SSM + Ansible"
      - Assume role policy: ec2.amazonaws.com

   b. Managed Policy Attachments:
      - AmazonSSMManagedInstanceCore (required for SSM Agent)
      - CloudWatchAgentServerPolicy (for metrics and logs)

   c. Custom Inline Policy: parameter_store_read
      - Name: "parameter-store-read"
      - Allow actions:
        * ssm:GetParameter
        * ssm:GetParameters
        * ssm:GetParametersByPath
      - Resource: arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/study-ssm-ansible/*
      - Allow kms:Decrypt for SecureString parameters (Resource: *)

   d. Instance Profile: ssm_ansible_profile
      - Name: "ssm-ansible-instance-profile"
      - Role: ssm_ansible_role

2. Update layers/200-iam/outputs.tf:
   - ssm_ansible_role_arn
   - ssm_ansible_role_name
   - ssm_ansible_instance_profile_name
   - ssm_ansible_instance_profile_arn

3. Create layers/200-iam/envs/sandbox.tfvars:
   - environment = "sandbox"
   - aws_region = "eu-central-1"
   - aws_account_id = "862378407079"

4. Update layers/200-iam/README.md:
   - Document SSM role purpose
   - List all policies
   - Show required permissions
   - Deployment instructions

IMPORTANT:
- Use data sources for managed policy ARNs
- Include proper policy JSON formatting
- Add tags to all resources
- Follow existing layer patterns

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 3)
```

**Success Criteria**:
- IAM role created
- Policies attached correctly
- Instance profile created
- Outputs defined

---

### Task 2.4: Pipeline Updates for New Layers

**Prompt for ZAI Worker**:
```
Update the pipeline scripts to include the new 150-ssm layer in the deployment order.

Files to modify:

1. pipeline/vars.sh:
   - Add "150-ssm" to LAYERS array (between 100-network and 200-iam)
   - Correct order: 100-network, 150-ssm, 200-iam, 300-compute, ...

2. Update Makefile (if layer-specific targets exist):
   - Ensure 150-ssm is recognized
   - No code changes needed if using generic layer targets

3. Test that layer ordering is correct:
   - 100-network (no dependencies)
   - 150-ssm (depends on: none, but will reference 100, 200, 300 via data sources)
   - 200-iam (no dependencies)
   - 300-compute (depends on: 100-network, 200-iam)

IMPORTANT:
- Check existing pipeline/vars.sh structure
- Maintain consistent naming
- Verify LAYERS array order

Reference: Project structure exploration
```

**Success Criteria**:
- 150-ssm in pipeline order
- Scripts recognize new layer
- No breaking changes

---

## Job 3: Terraform Infrastructure - Compute and SSM

**Working Directory**: `/Users/dennisvriend/projects/study-ssm-ansible`
**Branch**: `feature/terraform-compute-ssm`
**Dependencies**: Job 2 completion (needs network and IAM layers)
**Estimated Tasks**: 5

### Task 3.1: Compute Layer - AMI and Data Sources

**Prompt for ZAI Worker**:
```
Extend the 300-compute layer with data sources and basic configuration.

Files to modify/create:

1. layers/300-compute/main.tf:
   - Data source: aws_ami for Amazon Linux 2023
     * most_recent = true
     * owners = ["amazon"]
     * Filter: name = "al2023-ami-*-x86_64"
     * Filter: virtualization-type = "hvm"

   - Data source: terraform_remote_state for 100-network
     * backend = "local"
     * config.path = "../100-network/terraform.tfstate"

   - Data source: terraform_remote_state for 200-iam
     * backend = "local"
     * config.path = "../200-iam/terraform.tfstate"

2. layers/300-compute/variables.tf:
   - environment (required)
   - aws_region (default: "eu-central-1")
   - aws_account_id (required)
   - web_instance_type (default: "t3.micro")
   - app_instance_type (default: "t3.small")
   - bastion_instance_type (default: "t3.micro")
   - web_server_count (default: 2)
   - app_server_count (default: 2)

3. Create layers/300-compute/envs/sandbox.tfvars:
   - environment = "sandbox"
   - aws_region = "eu-central-1"
   - aws_account_id = "862378407079"
   - web_instance_type = "t3.micro"
   - app_instance_type = "t3.small"
   - bastion_instance_type = "t3.micro"

IMPORTANT:
- Use data.terraform_remote_state for cross-layer references
- Follow existing project patterns
- Validate AMI filter returns Amazon Linux 2023

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 4)
Existing patterns: other layer main.tf files
```

**Success Criteria**:
- AMI data source working
- Remote state references configured
- Variables defined

---

### Task 3.2: Compute Layer - Web Servers

**Prompt for ZAI Worker**:
```
Create web server EC2 instances in the 300-compute layer.

Create new file:

1. layers/300-compute/web-servers.tf:

   - Resource: aws_instance.web (count-based)
     * count = var.web_server_count (default: 2)
     * ami = data.aws_ami.amazon_linux_2023.id
     * instance_type = var.web_instance_type
     * subnet_id = element(data.terraform_remote_state.network.outputs.public_subnet_ids, count.index)
     * vpc_security_group_ids = [data.terraform_remote_state.network.outputs.web_security_group_id]
     * iam_instance_profile = data.terraform_remote_state.iam.outputs.ssm_ansible_instance_profile_name
     * user_data = templatefile("${path.module}/user-data-web.sh", { instance_name = "web-${count.index + 1}" })

     * Tags:
       - Name = "ssm-ansible-web-${count.index + 1}"
       - Role = "web"
       - Environment = var.environment
       - Stack = "demo"
       - ManagedBy = "SSM-Ansible"
       - AZ = element(["eu-central-1a", "eu-central-1b"], count.index)

     * lifecycle: create_before_destroy = true

   - Create user data script file: layers/300-compute/user-data-web.sh
     * #!/bin/bash
     * Set hostname to ${instance_name}
     * Ensure SSM agent is running
     * Basic system updates (yum update -y)
     * No application installation (Ansible handles this)

2. Add to layers/300-compute/outputs.tf:
   - web_server_ids = aws_instance.web[*].id
   - web_server_public_ips = aws_instance.web[*].public_ip
   - web_server_private_ips = aws_instance.web[*].private_ip

IMPORTANT:
- Use element() for round-robin subnet distribution
- User data should be minimal (Ansible does the rest)
- Ensure SSM agent starts on boot
- Proper tagging for SSM associations

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 4.2)
```

**Success Criteria**:
- Web instances created
- Distributed across AZs
- Proper tags applied
- Outputs defined

---

### Task 3.3: Compute Layer - App Servers and Bastion

**Prompt for ZAI Worker**:
```
Create application server and bastion EC2 instances in the 300-compute layer.

Create these files:

1. layers/300-compute/app-servers.tf:

   - Resource: aws_instance.app (count-based)
     * count = var.app_server_count (default: 2)
     * ami = data.aws_ami.amazon_linux_2023.id
     * instance_type = var.app_instance_type
     * subnet_id = element(data.terraform_remote_state.network.outputs.public_subnet_ids, count.index)
     * vpc_security_group_ids = [data.terraform_remote_state.network.outputs.app_security_group_id]
     * iam_instance_profile = data.terraform_remote_state.iam.outputs.ssm_ansible_instance_profile_name
     * user_data = templatefile("${path.module}/user-data-app.sh", { instance_name = "app-${count.index + 1}" })

     * Tags:
       - Name = "ssm-ansible-app-${count.index + 1}"
       - Role = "app"
       - Environment = var.environment
       - Stack = "demo"
       - ManagedBy = "SSM-Ansible"
       - AZ = element(["eu-central-1a", "eu-central-1b"], count.index)

   - Create user data: layers/300-compute/user-data-app.sh (similar to web)

2. layers/300-compute/bastion.tf:

   - Resource: aws_instance.bastion (single instance)
     * ami = data.aws_ami.amazon_linux_2023.id
     * instance_type = var.bastion_instance_type
     * subnet_id = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
     * vpc_security_group_ids = [data.terraform_remote_state.network.outputs.bastion_security_group_id]
     * iam_instance_profile = data.terraform_remote_state.iam.outputs.ssm_ansible_instance_profile_name
     * user_data = templatefile("${path.module}/user-data-bastion.sh", { instance_name = "bastion" })

     * Tags:
       - Name = "ssm-ansible-bastion"
       - Role = "bastion"
       - Environment = var.environment
       - Management = "true"
       - ManagedBy = "SSM-Ansible"

   - Create user data: layers/300-compute/user-data-bastion.sh

3. Add to layers/300-compute/outputs.tf:
   - app_server_ids = aws_instance.app[*].id
   - app_server_private_ips = aws_instance.app[*].private_ip
   - bastion_id = aws_instance.bastion.id
   - bastion_public_ip = aws_instance.bastion.public_ip

4. Update layers/300-compute/README.md:
   - Document all instance types
   - Show tagging strategy
   - Deployment instructions

IMPORTANT:
- App servers get private IPs (in public subnet but accessed via web servers)
- Bastion gets public IP for SSH access
- All instances need SSM agent running

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 4.2)
```

**Success Criteria**:
- App servers created
- Bastion created
- Proper security groups
- Outputs defined

---

### Task 3.4: SSM Layer - Directory Structure and S3

**Prompt for ZAI Worker**:
```
Create the new 150-ssm layer with basic structure and S3 bucket for association logs.

Create new layer directory and files:

1. layers/150-ssm/provider.tf:
   - Copy from another layer (100-network)
   - Update layer tag to "150-ssm"

2. layers/150-ssm/variables.tf:
   - environment (required)
   - aws_region (default: "eu-central-1")
   - aws_account_id (required)
   - github_repo_owner (default: "dennisvriend")
   - github_repo_name (default: "study-ssm-ansible")
   - github_repo_branch (default: "main")
   - ansible_path (default: "ansible")
   - association_schedule (default: "rate(10 minutes)")

3. layers/150-ssm/s3.tf:

   - Resource: aws_s3_bucket.ssm_logs
     * bucket = "study-ssm-ansible-logs-${var.aws_account_id}"
     * force_destroy = true (for easy cleanup)
     * Tags

   - Resource: aws_s3_bucket_public_access_block.ssm_logs
     * block_public_acls = true
     * block_public_policy = true
     * ignore_public_acls = true
     * restrict_public_buckets = true

   - Resource: aws_s3_bucket_lifecycle_configuration.ssm_logs
     * rule: delete objects after 7 days
     * status = "Enabled"

   - Resource: aws_s3_bucket_versioning.ssm_logs
     * status = "Disabled"

4. layers/150-ssm/outputs.tf:
   - ssm_logs_bucket_name
   - ssm_logs_bucket_arn

5. Create layers/150-ssm/envs/sandbox.tfvars:
   - environment = "sandbox"
   - aws_region = "eu-central-1"
   - aws_account_id = "862378407079"

6. layers/150-ssm/README.md:
   - Explain SSM State Manager purpose
   - List all associations
   - Deployment order (after 100, 200, 300)
   - GitHub token setup instructions

IMPORTANT:
- S3 bucket name must be globally unique
- Lifecycle policy keeps costs down
- Block all public access

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 5)
```

**Success Criteria**:
- Layer structure created
- S3 bucket configured
- Lifecycle policy active
- Variables and outputs defined

---

### Task 3.5: SSM Layer - Parameters and Associations

**Prompt for ZAI Worker**:
```
Create SSM parameters and State Manager associations in the 150-ssm layer.

Create these files:

1. layers/150-ssm/parameters.tf:

   - Resource: random_password.app_secret
     * length = 32
     * special = true

   - Resource: aws_ssm_parameter.app_database_url
     * name = "/study-ssm-ansible/app/database_url"
     * type = "String"
     * value = "sqlite:///app.db"
     * description = "Database URL for Flask app"

   - Resource: aws_ssm_parameter.app_secret_key
     * name = "/study-ssm-ansible/app/secret_key"
     * type = "SecureString"
     * value = random_password.app_secret.result
     * description = "Secret key for Flask app"

   - Resource: aws_ssm_parameter.nginx_worker_processes
     * name = "/study-ssm-ansible/nginx/worker_processes"
     * type = "String"
     * value = "2"

   - Resource: aws_ssm_parameter.environment_name
     * name = "/study-ssm-ansible/global/environment"
     * type = "String"
     * value = var.environment

   NOTE: GitHub token (/study-ssm-ansible/github/token) created manually via AWS CLI

2. layers/150-ssm/associations.tf:

   - Resource: aws_ssm_association.common_config
     * name = "study-ssm-ansible-common"
     * association_name = "common-configuration"
     * targets:
       - key = "tag:Environment"
       - values = [var.environment]
     * parameters:
       - SourceInfo = JSON with owner, repository, path, getOptions, tokenInfo
       - SourceType = ["GitHub"]
       - InstallDependencies = ["True"]
       - PlaybookFile = ["playbooks/common.yml"]
       - ExtraVariables = ["SSM=True ansible_python_interpreter=/usr/bin/python3"]
       - Verbose = ["-v"]
     * schedule_expression = var.association_schedule
     * output_location:
       - s3_bucket_name = aws_s3_bucket.ssm_logs.id
       - s3_key_prefix = "associations/common"

   - Resource: aws_ssm_association.web_servers
     * Similar structure for Role=web
     * PlaybookFile = ["playbooks/web-server.yml"]
     * s3_key_prefix = "associations/web"
     * depends_on = [aws_ssm_association.common_config]

   - Resource: aws_ssm_association.app_servers
     * Similar structure for Role=app
     * PlaybookFile = ["playbooks/app-server.yml"]
     * s3_key_prefix = "associations/app"
     * depends_on = [aws_ssm_association.common_config]

   - Resource: aws_ssm_association.bastion
     * Similar structure for Role=bastion
     * PlaybookFile = ["playbooks/bastion.yml"]
     * s3_key_prefix = "associations/bastion"
     * depends_on = [aws_ssm_association.common_config]

3. Update layers/150-ssm/outputs.tf:
   - association_ids (map of all association IDs)
   - parameter_arns (list of all parameter ARNs)

CRITICAL:
- SourceInfo must be valid JSON with tokenInfo: "{{ssm-secure:/study-ssm-ansible/github/token}}"
- Document name: "AWS-ApplyAnsiblePlaybooks"
- Schedule: rate(10 minutes) for study
- Dependencies: common runs first

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Phase 5.3)
Reference Obsidian note: /Users/dennisvriend/projects/obsidian-knowledge-base/reference/aws/ssm-ansible-monitoring-stack-terraform.md (Association examples)
```

**Success Criteria**:
- Parameters created
- Associations configured
- Schedule set correctly
- Dependencies defined

---

## Job 4: Documentation

**Working Directory**: `/Users/dennisvriend/projects/study-ssm-ansible`
**Branch**: `feature/documentation`
**Dependencies**: None (can run parallel)
**Estimated Tasks**: 6

### Task 4.1: Design Documentation

**Prompt for ZAI Worker**:
```
Create comprehensive design documentation for the SSM + Ansible study project.

Create file: references/DESIGN.md

Contents:
1. Architecture Overview
   - System diagram (ASCII art)
   - 5 EC2 instances with roles
   - VPC and network topology
   - SSM State Manager flow

2. Technical Stack
   - OpenTofu/Terraform
   - Amazon Linux 2023
   - Ansible 2.16+
   - AWS SSM State Manager
   - Python 3.11 + Flask
   - Nginx

3. Design Decisions
   - Why 5 instances (demonstrates multi-targeting)
   - Why Flask (Python virtualenv, systemd services)
   - Why 150-ssm layer (clean separation)
   - Why 10-minute schedule (fast iteration)
   - Why public subnets (cost savings)
   - Why manual GitHub PAT (security)

4. Network Architecture
   - VPC: 10.10.0.0/16
   - Subnet details
   - Security group rules
   - Routing

5. IAM Permissions
   - SSM role permissions
   - Parameter Store access
   - CloudWatch access

6. Tag Strategy
   - Environment, Role, Stack, AZ
   - How tags drive SSM targeting
   - Scaling to hundreds of servers

7. Cost Estimates
   - EC2: ~$30-40/month
   - S3: <$1/month
   - SSM: Free
   - Total: ~$30-50/month

Include diagrams, tables, and examples from approved plan.

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (full plan)
```

**Success Criteria**:
- Complete architecture documentation
- Clear diagrams
- All design decisions explained
- Cost estimates provided

---

### Task 4.2: Deployment Guide

**Prompt for ZAI Worker**:
```
Create step-by-step deployment guide for the SSM + Ansible study project.

Create file: references/DEPLOYMENT_GUIDE.md

Contents:
1. Prerequisites
   - AWS account (sandbox-ilionx-amf)
   - AWS CLI configured
   - OpenTofu installed
   - GitHub account
   - Git configured

2. Phase 1: GitHub Setup
   - Create GitHub Personal Access Token (scope: repo)
   - Instructions with screenshots
   - Where to store token

3. Phase 2: Store GitHub Token
   - AWS CLI command to put parameter
   - Verification command
   - Security notes

4. Phase 3: Deploy Infrastructure
   - Step-by-step layer deployment:
     * make layer-init LAYER=100-network ENV=sandbox
     * make layer-plan LAYER=100-network ENV=sandbox
     * make layer-apply LAYER=100-network ENV=sandbox
   - Repeat for: 200-iam, 300-compute, 150-ssm
   - Wait times between layers
   - What to verify after each layer

5. Phase 4: Verify SSM Registration
   - aws ssm describe-instance-information command
   - Expected output
   - Troubleshooting if instances don't appear

6. Phase 5: Trigger Associations
   - Manual trigger commands for first run
   - How to check association status
   - How to view logs in S3

7. Phase 6: Verification and Testing
   - Get instance IPs
   - Test web server (curl commands)
   - Test app server (via SSM Session Manager)
   - View CloudWatch metrics
   - Check S3 logs

8. Phase 7: Testing Configuration Drift
   - Simulate drift (stop service, delete file)
   - Wait for next association run
   - Verify restoration

9. Cleanup
   - Destroy all layers in reverse order
   - Verify S3 bucket deletion
   - Check for remaining resources

Include all commands from approved plan.

Reference: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md (Deployment Sequence)
```

**Success Criteria**:
- Complete deployment instructions
- All commands included
- Verification steps clear
- Troubleshooting included

---

### Task 4.3: SSM Concepts Documentation

**Prompt for ZAI Worker**:
```
Create learning documentation for AWS Systems Manager concepts.

Create file: references/SSM_CONCEPTS.md

Contents:
1. SSM Agent
   - What it is
   - Pre-installed on Amazon Linux 2023
   - Polling mechanism (every 5 minutes)
   - How it executes commands locally
   - No inbound ports required

2. SSM State Manager
   - Desired state configuration
   - Idempotent operations
   - Schedule-based execution
   - Compliance reporting
   - Drift detection

3. SSM Associations
   - What associations are
   - Linking documents to targets
   - Tag-based targeting
   - Schedule expressions (rate, cron)
   - Output to S3/CloudWatch
   - Dependencies between associations

4. SSM Parameter Store
   - Hierarchical organization
   - String vs SecureString
   - IAM integration
   - KMS encryption
   - Best practices

5. SSM Documents
   - JSON/YAML format
   - AWS-ApplyAnsiblePlaybooks document
   - Parameters and variables
   - Built-in vs custom documents

6. Pull Model vs Push Model
   - Traditional Ansible (push):
     * Control node runs playbooks
     * SSH required
     * Centralized execution
     * Network connectivity from control -> targets

   - SSM + Ansible (pull):
     * Each target runs playbooks locally
     * No SSH required
     * Distributed execution
     * Only HTTPS to AWS API endpoints
     * Better for hundreds of servers

7. Integration with Ansible
   - How SSM downloads playbooks from GitHub
   - ansible-playbook execution on localhost
   - Parameter Store lookups in Ansible
   - Output logging to S3

8. Scaling Patterns
   - Tag hierarchies
   - Multi-dimensional targeting
   - Rate controls
   - Error thresholds

Include examples, diagrams, and comparisons.

Reference: Obsidian note and approved plan
```

**Success Criteria**:
- Clear concept explanations
- Pull vs push comparison
- Examples included
- Scaling considerations

---

### Task 4.4: Ansible Concepts Documentation

**Prompt for ZAI Worker**:
```
Create learning documentation for Ansible concepts specific to SSM integration.

Create file: references/ANSIBLE_CONCEPTS.md

Contents:
1. Ansible Basics
   - YAML format
   - Declarative configuration
   - Idempotent operations
   - Task-based execution

2. Playbook Structure
   - hosts directive
   - connection type
   - become (sudo)
   - roles inclusion
   - pre_tasks and post_tasks
   - handlers

3. Roles
   - Directory structure (tasks, templates, handlers, files)
   - Role dependencies
   - Reusable units
   - Galaxy roles

4. Templates (Jinja2)
   - Variable substitution
   - Loops and conditionals
   - Filters
   - Common patterns

5. Variables
   - Precedence hierarchy
   - group_vars/ and host_vars/
   - Extra vars from command line
   - System facts
   - Parameter Store lookups

6. Handlers
   - Triggered by notify
   - Run once at end of play
   - Service restarts
   - Configuration reloads

7. SSM-Specific Patterns
   - MUST use: hosts: localhost
   - MUST use: connection: local
   - MUST use: become: yes
   - No inventory file needed
   - Tag-based conditionals: when: "'tag_Role_web' in group_names"
   - AWS SSM Parameter Store lookup plugin
   - Error handling for SSM failures

8. Best Practices
   - Idempotency (always safe to re-run)
   - Validation before changes
   - Handlers for service management
   - Logging to CloudWatch/S3
   - Testing locally before SSM deployment

9. Common Patterns
   - Install packages: ansible.builtin.yum
   - Deploy templates: ansible.builtin.template
   - Manage services: ansible.builtin.systemd
   - File operations: ansible.builtin.file, copy
   - Command execution: ansible.builtin.command (use sparingly)

Include code examples from the playbooks.

Reference: Created Ansible roles and playbooks
```

**Success Criteria**:
- Clear Ansible concepts
- SSM-specific patterns highlighted
- Code examples included
- Best practices documented

---

### Task 4.5: Troubleshooting Guide

**Prompt for ZAI Worker**:
```
Create comprehensive troubleshooting guide for common issues.

Create file: references/TROUBLESHOOTING.md

Contents:
1. Instance Not Appearing in SSM Console
   - Symptoms
   - Possible causes:
     * IAM instance profile not attached
     * SSM Agent not running
     * No internet connectivity
     * Security group blocking HTTPS (443)
   - Diagnosis commands
   - Solutions for each cause

2. Association Failing
   - Symptoms: Association shows "Failed" status
   - Possible causes:
     * GitHub token expired/incorrect
     * Playbook syntax error
     * Repository path incorrect
     * Missing Ansible dependencies
     * GitHub repo not accessible
   - How to view detailed error logs
   - Solutions

3. Configuration Not Applied
   - Symptoms: Manual changes not being reverted
   - Possible causes:
     * Ansible task not idempotent
     * Association not running (schedule issue)
     * Wrong targeting tags
     * SSM Agent stopped
   - Verification commands
   - Solutions

4. Playbook Execution Errors
   - Python interpreter not found
   - Module not found
   - Permission denied
   - Network connectivity issues
   - Solutions

5. Service Not Starting
   - Nginx won't start
   - Flask app fails
   - SystemD service errors
   - How to debug via Session Manager
   - Log locations

6. Parameter Store Access Denied
   - IAM permissions missing
   - KMS key access denied
   - Parameter not found
   - Solutions

7. S3 Logging Not Working
   - Bucket permissions
   - IAM role missing s3:PutObject
   - Solutions

8. Debugging Commands
   - Connect via Session Manager
   - View Ansible logs: /var/log/amazon/ssm/
   - Check service status
   - View systemd journals
   - Check S3 logs
   - View CloudWatch logs

9. Common SSM Commands
   - Describe instance information
   - Describe associations
   - List commands
   - Get command invocation details
   - Send manual command

Include all commands and examples.

Reference: Approved plan troubleshooting section
```

**Success Criteria**:
- All common issues covered
- Clear diagnosis steps
- Solutions provided
- Commands included

---

### Task 4.6: Scaling Patterns Documentation

**Prompt for ZAI Worker**:
```
Create documentation for scaling patterns to hundreds of servers.

Create file: references/SCALING_PATTERNS.md

Contents:
1. Tag Strategy for Scale
   - Multi-dimensional tags:
     * Environment (dev, staging, prod)
     * Role (web, app, db, cache)
     * Stack (microservice name)
     * AZ (availability zone)
     * Team (owning team)
   - Tag naming conventions
   - Consistent tagging policies

2. Association Targeting Patterns

   Pattern 1: Role-Based
   - Target all servers of specific role across all environments
   - Use case: Global updates
   - Example

   Pattern 2: Environment-Based
   - Target all servers in specific environment
   - Use case: Environment-specific config
   - Example

   Pattern 3: Multi-Dimensional
   - Combine multiple tags for fine-grained targeting
   - Use case: Specific role in specific environment
   - Example

   Pattern 4: Rate Controls
   - Limit concurrent executions
   - Prevent overwhelming services
   - Error thresholds
   - Example

3. Playbook Organization at Scale

   Option A: Single Playbook with Conditionals
   - Use when: statements based on tags
   - Pros: Single source of truth
   - Cons: Can become complex
   - Example

   Option B: Separate Playbooks per Role
   - One playbook per server role
   - Pros: Clear separation, easier to maintain
   - Cons: More associations to manage
   - Example (current approach)

4. Parameter Store Hierarchy
   - Organize parameters by hierarchy:
     /company/environment/role/parameter
   - Examples:
     /study-ssm-ansible/prod/web/nginx_workers
     /study-ssm-ansible/dev/app/debug_mode
   - GetParametersByPath usage

5. Auto Scaling Integration
   - Launch templates with IAM instance profile
   - User data to set proper tags
   - Associations automatically target new instances
   - No manual intervention required
   - Example configuration

6. Testing at Scale
   - Canary deployments (target 1 instance first)
   - Blue-green with tags
   - Rollback strategies
   - Validation before fleet-wide rollout

7. Monitoring at Scale
   - CloudWatch metrics per association
   - Compliance reporting
   - Drift detection across fleet
   - Alerting on failures

8. Real-World Example: 500 Web Servers
   - Tag structure
   - Association configuration
   - Rate controls (max 50 concurrent)
   - Error threshold (10% failure stops rollout)
   - Complete example

Include diagrams, tables, and code examples.

Reference: Approved plan and SSM best practices
```

**Success Criteria**:
- Scaling patterns documented
- Real-world examples
- Tag strategies explained
- Auto-scaling integration covered

---

## Job 5: Integration and Testing (Post-Implementation)

**Working Directory**: `/Users/dennisvriend/projects/study-ssm-ansible`
**Branch**: `feature/integration-testing`
**Dependencies**: Jobs 1, 2, 3 complete
**Estimated Tasks**: 2

### Task 5.1: Update Root README

**Prompt for ZAI Worker**:
```
Update the root README.md to document the SSM + Ansible study project.

Modify file: README.md

Add new section after existing content:

## SSM + Ansible Study Project

A hands-on study project demonstrating AWS Systems Manager + Ansible integration for scalable, pull-based configuration management.

### Overview

This project implements a 5-instance environment managed entirely through SSM State Manager and Ansible, demonstrating:
- Pull-based configuration management (no SSH required)
- Tag-based targeting for server groups
- Deterministic configuration with periodic enforcement
- Scalable patterns for hundreds of servers

### Architecture

- **5 EC2 Instances**: 2 web (Nginx), 2 app (Flask), 1 bastion
- **Network**: VPC 10.10.0.0/16 with 2 public subnets
- **Configuration**: Ansible playbooks executed via SSM every 10 minutes
- **Management**: GitHub repo + SSM State Manager + Parameter Store

### Quick Start

1. **Prerequisites**: AWS account (sandbox-ilionx-amf), OpenTofu, GitHub PAT
2. **Deploy**: See [DEPLOYMENT_GUIDE.md](references/DEPLOYMENT_GUIDE.md)
3. **Learn**: Read [SSM_CONCEPTS.md](references/SSM_CONCEPTS.md) and [ANSIBLE_CONCEPTS.md](references/ANSIBLE_CONCEPTS.md)

### Documentation

- [Design Documentation](references/DESIGN.md) - Architecture and decisions
- [Deployment Guide](references/DEPLOYMENT_GUIDE.md) - Step-by-step deployment
- [SSM Concepts](references/SSM_CONCEPTS.md) - Systems Manager learning
- [Ansible Concepts](references/ANSIBLE_CONCEPTS.md) - Ansible patterns for SSM
- [Troubleshooting](references/TROUBLESHOOTING.md) - Common issues and solutions
- [Scaling Patterns](references/SCALING_PATTERNS.md) - Patterns for 100+ servers

### Project Structure

```
study-ssm-ansible/
├── ansible/              # Ansible playbooks and roles
├── layers/               # Terraform infrastructure layers
│   ├── 100-network/     # VPC, subnets, security groups
│   ├── 150-ssm/         # SSM associations and parameters
│   ├── 200-iam/         # IAM roles for SSM
│   └── 300-compute/     # EC2 instances
└── references/          # Learning documentation
```

### Key Learning Outcomes

- SSM State Manager associations and scheduling
- Pull model vs push model configuration management
- IAM roles and Parameter Store integration
- Tag-based server targeting at scale
- Ansible best practices for SSM integration
- Drift detection and remediation

### Cost

Approximately $30-50/month for sandbox environment. Destroy with `make destroy-all ENV=sandbox` when done.

---

Keep all existing content, just add this section.

Reference: Approved plan and existing README structure
```

**Success Criteria**:
- README updated
- Links to documentation working
- Quick start instructions clear
- Project structure explained

---

### Task 5.2: Create Makefile Helper Commands

**Prompt for ZAI Worker**:
```
Add SSM-specific helper commands to the Makefile for easier management.

Modify file: Makefile

Add new section after existing layer commands:

## SSM Management Commands

.PHONY: ssm-check ssm-trigger ssm-logs ssm-session

ssm-check:
	@echo "Checking SSM managed instances..."
	aws ssm describe-instance-information \
		--region $(AWS_REGION) \
		--query "InstanceInformationList[*].[InstanceId,PingStatus,PlatformName,IPAddress]" \
		--output table

ssm-trigger:
	@echo "Manually triggering SSM associations..."
	@echo "Triggering common configuration..."
	aws ssm send-command \
		--document-name "AWS-ApplyAnsiblePlaybooks" \
		--targets "Key=tag:Environment,Values=$(ENV)" \
		--parameters file://$(CURDIR)/layers/150-ssm/trigger-common.json \
		--region $(AWS_REGION)

ssm-logs:
	@echo "Listing recent SSM association logs..."
	aws s3 ls s3://study-ssm-ansible-logs-$(AWS_ACCOUNT_ID)/associations/ --recursive | tail -20

ssm-session:
	@read -p "Enter Instance ID: " INSTANCE_ID; \
	aws ssm start-session --target $$INSTANCE_ID --region $(AWS_REGION)

# Variables
AWS_REGION ?= eu-central-1
AWS_ACCOUNT_ID ?= 862378407079
ENV ?= sandbox

Also create: layers/150-ssm/trigger-common.json
```json
{
  "SourceInfo": ["{\"owner\":\"dennisvriend\",\"repository\":\"study-ssm-ansible\",\"path\":\"ansible\",\"getOptions\":\"branch:main\",\"tokenInfo\":\"{{ssm-secure:/study-ssm-ansible/github/token}}\"}"],
  "SourceType": ["GitHub"],
  "InstallDependencies": ["True"],
  "PlaybookFile": ["playbooks/common.yml"],
  "ExtraVariables": ["SSM=True ansible_python_interpreter=/usr/bin/python3"],
  "Verbose": ["-v"]
}
```

Add usage instructions to README:
- `make ssm-check` - Check SSM managed instances
- `make ssm-trigger ENV=sandbox` - Manually trigger associations
- `make ssm-logs` - View recent association logs
- `make ssm-session` - Connect to instance via Session Manager

Reference: Existing Makefile structure
```

**Success Criteria**:
- Makefile commands added
- Helper JSON files created
- Commands work correctly
- README documents usage

---

## Execution Summary

**Total Jobs**: 5
**Total Tasks**: 23

**Job Execution Order**:
1. Job 1 (Ansible) - Can start immediately
2. Job 2 (Terraform Base) - Can run parallel with Job 1
3. Job 3 (Terraform Compute/SSM) - After Job 2 completes
4. Job 4 (Documentation) - Can run parallel with Jobs 1-3
5. Job 5 (Integration) - After Jobs 1-3 complete

**Estimated Timeline**:
- Job 1: 4-6 hours (6 tasks)
- Job 2: 2-3 hours (4 tasks)
- Job 3: 3-4 hours (5 tasks)
- Job 4: 4-5 hours (6 tasks)
- Job 5: 1-2 hours (2 tasks)

**Total Estimated Time**: 14-20 hours of ZAI worker time

**Parallelization**:
- Jobs 1, 2, 4 can run in parallel (save ~6-8 hours)
- Actual calendar time: ~8-12 hours with parallelization

---

## Post-Implementation Verification

After all jobs complete:

1. **Code Review**:
   - Terraform validates and plans successfully
   - Ansible playbooks have no syntax errors
   - All files follow project conventions

2. **Manual Testing**:
   - Deploy to sandbox environment
   - Verify SSM registration
   - Trigger associations manually
   - Test web servers (curl)
   - Test app servers (via Session Manager)
   - Verify S3 logs
   - Test configuration drift restoration

3. **Documentation Review**:
   - All links work
   - Commands are correct
   - Examples are accurate
   - Diagrams are clear

4. **Final Cleanup**:
   - Remove any debug code
   - Update CLAUDE.md if needed
   - Create git commit with all changes
   - Push to GitHub

---

## Notes for ZAI Workers

**Important Conventions**:
- Follow existing Terraform patterns in other layers
- Use `ansible.builtin.` prefix for all Ansible modules
- All Ansible playbooks: `hosts: localhost`, `connection: local`, `become: yes`
- Tag all AWS resources properly (Environment, Role, ManagedBy)
- Use remote state for cross-layer references
- Include comprehensive comments and documentation

**Testing Locally**:
- Terraform: `tofu validate`, `tofu fmt`, `tofu plan`
- Ansible: `ansible-playbook --syntax-check`, `ansible-lint`

**Reference Materials**:
- Approved plan: /Users/dennisvriend/.claude/plans/quirky-napping-pancake.md
- Obsidian note: /Users/dennisvriend/projects/obsidian-knowledge-base/reference/aws/ssm-ansible-monitoring-stack-terraform.md
- Existing project structure for patterns

**Questions/Blockers**:
- Tag @dennisvriend in commit messages if clarification needed
- Document assumptions in code comments
- Create TODO comments for items needing human review
