# Ansible Playbooks for SSM Study Project

This directory contains Ansible playbooks and roles designed to execute via AWS Systems Manager (SSM) State Manager.

## Architecture

SSM State Manager executes Ansible playbooks by:
1. Running the playbook locally on an SSM-managed instance
2. Using the SSM document `AWS-ApplyAnsiblePlaybooks`
3. Targeting instances via tags or instance IDs
4. Reading playbooks from S3 or local sources

## Directory Structure

```
ansible/
├── playbooks/              # Main playbook files
├── roles/                  # Reusable Ansible roles
│   ├── common/            # Common configuration (time, packages, users)
│   ├── nginx/             # Nginx web server setup
│   ├── flask-app/         # Flask application deployment
│   └── monitoring/        # Monitoring and logging setup
├── group_vars/            # Variables grouped by target tags
├── ansible.cfg            # Ansible configuration
└── README.md
```

## Roles

| Role | Purpose | Target |
|------|---------|--------|
| common | Base system configuration, common packages, time sync | All instances |
| nginx | Nginx installation and configuration | Instances tagged `Role: web` |
| flask-app | Flask app deployment with Gunicorn | Instances tagged `Role: app` |
| monitoring | CloudWatch agent and logging | All instances |

## Execution via SSM State Manager

### Prerequisites
1. Playbooks uploaded to S3 bucket
2. SSM document configured with playbook paths
3. Target instances with SSM agent installed
4. IAM role with S3 read permissions

### Creating SSM Association

```bash
aws ssm create-association \
  --name "AWS-ApplyAnsiblePlaybooks" \
  --targets "Key=tag:Role,Values=web" \
  --parameters '{"SourceType":["S3"],"SourceInfo":["{\"path\":\"https://s3.amazonaws.com/my-bucket/ansible/playbooks/web.yml\"}"],"InstallDependencies":["True"],"PlaybookFile":["web.yml"],"ExtraVariables":["SSM=True"],"Check":["False"]}' \
  --schedule-expression "cron(0 2 * * ? *)"
```

### Testing Locally

```bash
# Test against localhost (for SSM execution simulation)
ansible-playbook playbooks/base-config.yml --connection=local

# Test with specific inventory
ansible-playbook playbooks/web.yml -i inventory/hosts.ini

# Dry run
ansible-playbook playbooks/app.yml --check
```

## Variable precedence

1. Role defaults (lowest)
2. group_vars/tag_Role_*.yml (tag-based)
3. group_vars/all.yml (global)
4. Extra variables (highest - passed via SSM)

## SSM-Specific Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| ssm_execution | Set to True when running via SSM | False |
| aws_region | AWS region for CloudWatch | eu-central-1 |
| environment | Deployment environment | dev |

## Troubleshooting

### Common Issues

**Playbook fails with connection error**
- Verify SSM agent is running: `sudo systemctl status amazon-ssm-agent`
- Check instance has proper IAM role
- Ensure instance is in managed instances list

**Fact caching errors**
- Clear cache: `rm -rf /tmp/ansible_facts/*`
- Check fact_caching_connection in ansible.cfg

**Role not found**
- Verify roles_path in ansible.cfg
- Check role directory structure matches Ansible requirements

### Viewing Execution History

```bash
aws ssm list-association-executions --association-id <association-id>
aws ssm get-automation-execution --automation-execution-id <execution-id>
```
