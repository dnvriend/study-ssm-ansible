# Project Memory - SSM + Ansible Study Project

## Project Context

**Project Name**: study-ssm-ansible
**Purpose**: Learning project to understand AWS Systems Manager + Ansible integration for scalable configuration management
**Owner**: Dennis Vriend
**Environment**: sandbox-ilionx-amf account (862378407079) in eu-central-1
**Repository**: https://github.com/dennisvriend/study-ssm-ansible

## Project Goal

Demonstrate pull-based configuration management using SSM State Manager + Ansible that scales to hundreds of servers, with:
- 5 EC2 instances (2 web, 2 app, 1 bastion)
- Tag-based targeting via SSM associations
- Ansible playbooks executed locally every 10 minutes
- Deterministic configuration with drift prevention
- No SSH required - all management via SSM Agent

## Key Learning Objectives

1. **SSM State Manager**: Associations, scheduling, tag-based targeting
2. **Pull vs Push Model**: SSM Agent executing locally vs traditional SSH-based Ansible
3. **IAM Roles**: Permissions for SSM, Parameter Store, CloudWatch
4. **Deterministic Config**: 10-minute enforcement prevents drift
5. **Scalability Patterns**: Tag hierarchies for hundreds of servers
6. **Ansible Best Practices**: Roles, templates, handlers, idempotency

## Architecture Summary

**Network**:
- VPC: 10.10.0.0/16
- 2 Public Subnets: 10.10.1.0/24 (eu-central-1a), 10.10.2.0/24 (eu-central-1b)
- Internet Gateway (no NAT Gateway - cost savings)

**Instances**:
- 2x Web Servers (t3.micro) - Nginx serving static content - Tag: Role=web
- 2x App Servers (t3.small) - Flask API with systemd - Tag: Role=app
- 1x Bastion (t3.micro) - SSH access point - Tag: Role=bastion

**Configuration Management**:
- SSM State Manager associations execute every 10 minutes
- Ansible playbooks stored in GitHub (public repo)
- GitHub PAT stored in SSM Parameter Store: `/study-ssm-ansible/github/token` (manual setup)
- Playbooks run locally: `hosts: localhost`, `connection: local`, `become: yes`

**IAM**:
- Role: ssm-ansible-ec2-role
- Policies: AmazonSSMManagedInstanceCore, CloudWatchAgentServerPolicy
- Custom policy: Parameter Store read access to `/study-ssm-ansible/*`

## Implementation Status

**Current Phase**: Planning completed, CCS jobs and tasks created

### Claude Code Scheduler Jobs Created

**Total**: 5 jobs, 23 tasks

#### Job 1: Ansible Implementation
- **Job ID**: `1a54a5dd-0994-43dc-9639-1efb43c98259`
- **Branch**: `feature/ansible-playbooks`
- **Tasks**: 6 (directory structure, common role, nginx role, flask-app role, monitoring role, playbooks)
- **Status**: Ready to start
- **Dependencies**: None

#### Job 2: Terraform Base Layers
- **Job ID**: `86e56609-5666-4d4d-80b0-69b6b5a36972`
- **Branch**: `feature/terraform-base-layers`
- **Tasks**: 4 (network VPC, security groups, IAM roles, pipeline updates)
- **Status**: Ready to start
- **Dependencies**: None

#### Job 3: Terraform Compute and SSM
- **Job ID**: `675cf9a4-3b94-4260-82f3-6fdb05de8066`
- **Branch**: `feature/terraform-compute-ssm`
- **Tasks**: 5 (compute AMI, web servers, app servers/bastion, SSM layer S3, SSM parameters/associations)
- **Status**: Waiting for Job 2
- **Dependencies**: Job 2 (needs network and IAM layers)

#### Job 4: Documentation
- **Job ID**: `fe6ad032-f88c-4423-9c3e-828baeee8997`
- **Branch**: `feature/documentation`
- **Tasks**: 6 (design, deployment guide, SSM concepts, Ansible concepts, troubleshooting, scaling patterns)
- **Status**: Ready to start
- **Dependencies**: None

#### Job 5: Integration and Testing
- **Job ID**: `2829fdcc-0682-4dc6-8d1c-15a691b8774e`
- **Branch**: `feature/integration-testing`
- **Tasks**: 2 (update README, Makefile helpers)
- **Status**: Waiting for Jobs 1-3
- **Dependencies**: Jobs 1, 2, 3 complete

### Execution Strategy

**Phase 1** (Parallel):
```bash
claude-code-scheduler cli jobs run 1a54a5dd-0994-43dc-9639-1efb43c98259  # Ansible
claude-code-scheduler cli jobs run 86e56609-5666-4d4d-80b0-69b6b5a36972  # Terraform Base
claude-code-scheduler cli jobs run fe6ad032-f88c-4423-9c3e-828baeee8997  # Documentation
```

**Phase 2** (After Job 2):
```bash
claude-code-scheduler cli jobs run 675cf9a4-3b94-4260-82f3-6fdb05de8066  # Terraform Compute/SSM
```

**Phase 3** (After Jobs 1-3):
```bash
claude-code-scheduler cli jobs run 2829fdcc-0682-4dc6-8d1c-15a691b8774e  # Integration
```

## Project Structure

```
study-ssm-ansible/
├── ansible/                          # Ansible playbooks (to be created)
│   ├── playbooks/                    # common.yml, web-server.yml, app-server.yml, bastion.yml
│   ├── roles/                        # common, nginx, flask-app, monitoring
│   ├── group_vars/                   # all.yml, tag_Role_web.yml, tag_Role_app.yml
│   └── ansible.cfg
│
├── layers/                           # Terraform infrastructure
│   ├── 100-network/                 # VPC, subnets, security groups (to be extended)
│   ├── 150-ssm/                     # SSM associations, parameters, S3 logs (NEW - to be created)
│   ├── 200-iam/                     # IAM roles for SSM (to be extended)
│   ├── 300-compute/                 # EC2 instances (to be extended)
│   └── [other layers unchanged]
│
└── references/                       # Documentation and planning
    ├── todo.md                       # Complete task breakdown for ZAI workers
    ├── CCS_JOBS_SUMMARY.md          # Job IDs and execution guide
    ├── memory.md                     # This file - project context
    ├── DESIGN.md                     # Architecture documentation (to be created)
    ├── DEPLOYMENT_GUIDE.md          # Step-by-step deployment (to be created)
    ├── SSM_CONCEPTS.md              # SSM learning notes (to be created)
    ├── ANSIBLE_CONCEPTS.md          # Ansible learning notes (to be created)
    ├── TROUBLESHOOTING.md           # Common issues (to be created)
    └── SCALING_PATTERNS.md          # Scaling to 100+ servers (to be created)
```

## Key Files and Locations

### Critical Reference Files
- **Approved Plan**: `/Users/dennisvriend/.claude/plans/quirky-napping-pancake.md`
- **Task Breakdown**: `./references/todo.md`
- **Job Summary**: `./references/CCS_JOBS_SUMMARY.md`
- **Obsidian Reference**: `/Users/dennisvriend/projects/obsidian-knowledge-base/reference/aws/ssm-ansible-monitoring-stack-terraform.md`

### Key Patterns to Follow
- **Terraform**: Follow existing patterns from other layers (provider.tf, variables.tf, outputs.tf structure)
- **Ansible**: MUST use `hosts: localhost`, `connection: local`, `become: yes`
- **Ansible Modules**: Always use `ansible.builtin.` prefix
- **AWS Tags**: All resources tagged with Environment, Role, ManagedBy
- **State References**: Use `terraform_remote_state` for cross-layer dependencies

## Important Decisions Made

1. **5 Instances**: Demonstrates multi-instance tag-based targeting for realistic scaling patterns
2. **Flask API**: Python virtualenv, application deployment, systemd service management
3. **150-ssm Layer**: Clean separation of SSM resources between IAM (200) and Compute (300)
4. **Manual GitHub PAT**: Keep secrets out of Terraform state for security
5. **10-Minute Schedule**: Fast iteration for study (production typically 30-60 minutes)
6. **Public Subnets**: Simplified sandbox setup (no NAT Gateway costs ~$30/month savings)
7. **Mono-repo**: Ansible and Terraform together for easier management

## SSM Associations Strategy

Each association targets specific instance roles via tags:

1. **Common Association**:
   - Targets: `Environment=sandbox` (all instances)
   - Playbook: `playbooks/common.yml`
   - Purpose: Base configuration (packages, users, security, motd)
   - Schedule: Every 10 minutes
   - Runs first

2. **Web Association**:
   - Targets: `Role=web` (2 web servers)
   - Playbook: `playbooks/web-server.yml`
   - Purpose: Nginx installation and configuration
   - Depends on: Common association

3. **App Association**:
   - Targets: `Role=app` (2 app servers)
   - Playbook: `playbooks/app-server.yml`
   - Purpose: Flask API deployment with systemd
   - Depends on: Common association

4. **Bastion Association**:
   - Targets: `Role=bastion` (1 bastion)
   - Playbook: `playbooks/bastion.yml`
   - Purpose: SSH hardening and enhanced logging
   - Depends on: Common association

## SSM Parameter Store Hierarchy

```
/study-ssm-ansible/
├── github/
│   └── token                         # GitHub PAT (SecureString, manual creation)
├── app/
│   ├── database_url                  # sqlite:///app.db (String)
│   └── secret_key                    # Random 32 chars (SecureString)
├── nginx/
│   └── worker_processes              # 2 (String)
└── global/
    └── environment                   # sandbox (String)
```

## Layer Dependencies

```
100-network (VPC, subnets, security groups)
    ├─ No dependencies
    └─ Outputs: vpc_id, subnet_ids, security_group_ids

150-ssm (SSM associations, parameters, S3 logs)
    ├─ No Terraform dependencies (but references others for validation)
    └─ Outputs: association_ids, parameter_arns, s3_bucket_name

200-iam (SSM IAM roles and policies)
    ├─ No dependencies
    └─ Outputs: instance_profile_name, instance_profile_arn, role_arn

300-compute (EC2 instances)
    ├─ Depends on: 100-network (subnets, security groups)
    ├─ Depends on: 200-iam (instance profile)
    └─ Outputs: instance_ids, public_ips, private_ips

Deployment order: 100-network → 200-iam → 300-compute → 150-ssm
```

## Deployment Workflow (Manual)

### Prerequisites
1. AWS CLI configured for sandbox-ilionx-amf account
2. OpenTofu installed
3. GitHub account with PAT (scope: repo)
4. Git configured

### Phase 1: GitHub Setup
1. Commit Ansible playbooks to repository
2. Generate GitHub PAT: https://github.com/settings/tokens
3. Store PAT in SSM Parameter Store:
   ```bash
   aws ssm put-parameter \
     --name "/study-ssm-ansible/github/token" \
     --value "ghp_xxxxxxxxxxxx" \
     --type "SecureString" \
     --region eu-central-1
   ```

### Phase 2: Deploy Infrastructure
```bash
# Network
make layer-apply LAYER=100-network ENV=sandbox

# IAM
make layer-apply LAYER=200-iam ENV=sandbox

# Compute
make layer-apply LAYER=300-compute ENV=sandbox

# Wait 2-3 minutes for SSM agent registration

# SSM
make layer-apply LAYER=150-ssm ENV=sandbox
```

### Phase 3: Verify and Test
```bash
# Check SSM managed instances
aws ssm describe-instance-information --region eu-central-1

# Trigger associations manually (first time)
make ssm-trigger ENV=sandbox

# Get web server IP
make layer-outputs LAYER=300-compute ENV=sandbox

# Test web server
curl http://<WEB_IP>

# Connect via Session Manager
make ssm-session  # Enter instance ID when prompted
```

### Phase 4: Cleanup
```bash
# Destroy in reverse order
make layer-destroy LAYER=150-ssm ENV=sandbox
make layer-destroy LAYER=300-compute ENV=sandbox
make layer-destroy LAYER=200-iam ENV=sandbox
make layer-destroy LAYER=100-network ENV=sandbox
```

## Cost Estimates

- **5x EC2 instances**: ~$30-40/month (2 micro + 2 small + 1 micro)
- **S3 storage**: <$1/month (logs with 7-day lifecycle)
- **SSM State Manager**: FREE
- **Parameter Store (standard)**: FREE
- **Data Transfer**: Minimal (sandbox usage)

**Total**: ~$30-50/month for sandbox environment

**Cost Optimizations**:
- No NAT Gateway (saves ~$30/month)
- Public subnets with IGW (free)
- Small instance types (t3.micro/small)
- S3 lifecycle deletion (7 days)

## Known Limitations and Notes

1. **Public Subnets**: All instances in public subnets (not production-ready)
2. **Study Environment**: No high availability, no auto-scaling (intentional)
3. **GitHub PAT**: Manual setup required (not in Terraform state)
4. **Amazon Linux 2023**: SSM agent pre-installed, Python 3.11
5. **10-Minute Schedule**: Fast for study, but aggressive for production
6. **Sandbox Account**: Limited to eu-central-1 region
7. **No CI/CD**: Manual deployment only (tutorial style)

## Next Steps After Implementation

1. **Test Configuration Drift**: Manually change config, wait 10 minutes, verify SSM restores
2. **Update Playbooks**: Modify Ansible, commit, push, verify SSM pulls changes
3. **Scale Testing**: Add more instances with same tags, verify auto-targeting
4. **Advanced Topics**: Custom SSM documents, VPC endpoints, Auto Scaling integration
5. **Production Patterns**: Multi-environment, rate controls, error thresholds

## Important Commands

### CCS Management
```bash
# List all jobs
claude-code-scheduler cli jobs list

# Get job status
claude-code-scheduler cli jobs get <job-id>

# List tasks for job
claude-code-scheduler cli jobs tasks <job-id>

# List recent runs
claude-code-scheduler cli runs list

# Check system state
claude-code-scheduler cli state
```

### Layer Management
```bash
# Plan layer
make layer-plan LAYER=<layer> ENV=sandbox

# Apply layer
make layer-apply LAYER=<layer> ENV=sandbox

# Destroy layer
make layer-destroy LAYER=<layer> ENV=sandbox

# Show outputs
make layer-outputs LAYER=<layer> ENV=sandbox
```

### SSM Management
```bash
# Check managed instances
make ssm-check

# Trigger associations
make ssm-trigger ENV=sandbox

# View logs
make ssm-logs

# Connect to instance
make ssm-session
```

## Context for Future Claude Sessions

When resuming this project:

1. **Current State**: Planning complete, CCS jobs created with 23 tasks, ready for ZAI workers to execute
2. **Next Action**: Start Phase 1 jobs in parallel (Jobs 1, 2, 4)
3. **Reference Files**: Check `./references/CCS_JOBS_SUMMARY.md` for job IDs and execution strategy
4. **Task Details**: All prompts and specifications in `./references/todo.md`
5. **Architecture**: Full design in approved plan at `/Users/dennisvriend/.claude/plans/quirky-napping-pancake.md`

## Key Contacts and Resources

- **Owner**: Dennis Vriend (dnvriend@gmail.com)
- **Company**: Ilionx
- **AWS Account**: sandbox-ilionx-amf (862378407079)
- **Region**: eu-central-1
- **GitHub**: dennisvriend/study-ssm-ansible
- **Obsidian Knowledge Base**: `/Users/dennisvriend/projects/obsidian-knowledge-base`

## Lessons Learned (To Be Updated)

*This section will be populated as the project progresses and learning objectives are achieved.*

---

**Last Updated**: 2026-01-04
**Status**: Planning Complete, Ready for Implementation
**Next Milestone**: Execute Phase 1 CCS jobs (Ansible, Terraform Base, Documentation)
