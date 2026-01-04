# Claude Code Scheduler - Job and Task Summary

## Overview

All jobs and tasks have been created in Claude Code Scheduler for the SSM + Ansible study project implementation.

## Job IDs and Details

### Job 1: Ansible Implementation
- **Job ID**: `1a54a5dd-0994-43dc-9639-1efb43c98259`
- **Branch**: `feature/ansible-playbooks`
- **Status**: pending
- **Dependencies**: None (can start immediately)
- **Tasks**: 6
  1. Task 1.1: Ansible Directory Structure and Configuration
  2. Task 1.2: Common Role Implementation
  3. Task 1.3: Nginx Role Implementation
  4. Task 1.4: Flask App Role Implementation
  5. Task 1.5: Monitoring Role Implementation
  6. Task 1.6: Playbooks Implementation

**Run Command**:
```bash
claude-code-scheduler cli jobs run 1a54a5dd-0994-43dc-9639-1efb43c98259
```

---

### Job 2: Terraform Base Layers
- **Job ID**: `86e56609-5666-4d4d-80b0-69b6b5a36972`
- **Branch**: `feature/terraform-base-layers`
- **Status**: pending
- **Dependencies**: None (can run parallel with Job 1)
- **Tasks**: 4
  1. Task 2.1: Network Layer - VPC and Subnets
  2. Task 2.2: Network Layer - Security Groups
  3. Task 2.3: IAM Layer - SSM Roles and Policies
  4. Task 2.4: Pipeline Updates for New Layers

**Run Command**:
```bash
claude-code-scheduler cli jobs run 86e56609-5666-4d4d-80b0-69b6b5a36972
```

---

### Job 3: Terraform Compute and SSM
- **Job ID**: `675cf9a4-3b94-4260-82f3-6fdb05de8066`
- **Branch**: `feature/terraform-compute-ssm`
- **Status**: pending
- **Dependencies**: Job 2 completion (needs network and IAM layers)
- **Tasks**: 5
  1. Task 3.1: Compute Layer - AMI and Data Sources
  2. Task 3.2: Compute Layer - Web Servers
  3. Task 3.3: Compute Layer - App Servers and Bastion
  4. Task 3.4: SSM Layer - Directory Structure and S3
  5. Task 3.5: SSM Layer - Parameters and Associations

**Run Command** (after Job 2 completes):
```bash
claude-code-scheduler cli jobs run 675cf9a4-3b94-4260-82f3-6fdb05de8066
```

---

### Job 4: Documentation
- **Job ID**: `fe6ad032-f88c-4423-9c3e-828baeee8997`
- **Branch**: `feature/documentation`
- **Status**: pending
- **Dependencies**: None (can run parallel with Jobs 1-3)
- **Tasks**: 6
  1. Task 4.1: Design Documentation
  2. Task 4.2: Deployment Guide
  3. Task 4.3: SSM Concepts Documentation
  4. Task 4.4: Ansible Concepts Documentation
  5. Task 4.5: Troubleshooting Guide
  6. Task 4.6: Scaling Patterns Documentation

**Run Command**:
```bash
claude-code-scheduler cli jobs run fe6ad032-f88c-4423-9c3e-828baeee8997
```

---

### Job 5: Integration and Testing
- **Job ID**: `2829fdcc-0682-4dc6-8d1c-15a691b8774e`
- **Branch**: `feature/integration-testing`
- **Status**: pending
- **Dependencies**: Jobs 1, 2, 3 complete
- **Tasks**: 2
  1. Task 5.1: Update Root README
  2. Task 5.2: Create Makefile Helper Commands

**Run Command** (after Jobs 1-3 complete):
```bash
claude-code-scheduler cli jobs run 2829fdcc-0682-4dc6-8d1c-15a691b8774e
```

---

## Execution Strategy

### Phase 1: Parallel Execution (Start Immediately)
Run these jobs in parallel as they have no dependencies:

```bash
# Terminal 1: Ansible Implementation
claude-code-scheduler cli jobs run 1a54a5dd-0994-43dc-9639-1efb43c98259

# Terminal 2: Terraform Base Layers
claude-code-scheduler cli jobs run 86e56609-5666-4d4d-80b0-69b6b5a36972

# Terminal 3: Documentation
claude-code-scheduler cli jobs run fe6ad032-f88c-4423-9c3e-828baeee8997
```

### Phase 2: Dependent Execution (After Job 2)
Once Job 2 completes, start Job 3:

```bash
# Wait for Job 2 to complete, then:
claude-code-scheduler cli jobs run 675cf9a4-3b94-4260-82f3-6fdb05de8066
```

### Phase 3: Integration (After Jobs 1-3)
Once Jobs 1, 2, and 3 are complete, start Job 5:

```bash
# Wait for Jobs 1, 2, 3 to complete, then:
claude-code-scheduler cli jobs run 2829fdcc-0682-4dc6-8d1c-15a691b8774e
```

---

## Monitoring Commands

### Check Job Status
```bash
# List all jobs
claude-code-scheduler cli jobs list

# Get specific job details
claude-code-scheduler cli jobs get <job-id>

# List tasks for a job
claude-code-scheduler cli jobs tasks <job-id>
```

### Check Run Status
```bash
# List recent runs
claude-code-scheduler cli runs list

# Get run details
claude-code-scheduler cli runs get <run-id>

# Stop a running task
claude-code-scheduler cli runs stop <run-id>
```

### View State
```bash
# Get aggregated state
claude-code-scheduler cli state

# Check scheduled tasks
claude-code-scheduler cli scheduler
```

---

## Task Details Reference

All task details with complete prompts and requirements are documented in:
- **Full breakdown**: `./references/todo.md`
- **Architecture plan**: `/Users/dennisvriend/.claude/plans/quirky-napping-pancake.md`
- **Obsidian reference**: `/Users/dennisvriend/projects/obsidian-knowledge-base/reference/aws/ssm-ansible-monitoring-stack-terraform.md`

---

## Key Information for ZAI Workers

### Important File Locations
- **Working Directory**: `/Users/dennisvriend/projects/study-ssm-ansible`
- **Task Breakdown**: `./references/todo.md`
- **Approved Plan**: `/Users/dennisvriend/.claude/plans/quirky-napping-pancake.md`
- **Reference Note**: `/Users/dennisvriend/projects/obsidian-knowledge-base/reference/aws/ssm-ansible-monitoring-stack-terraform.md`

### Coding Standards
- **Terraform**: Follow existing patterns in other layers
- **Ansible**: Use `ansible.builtin.` prefix for all modules
- **Ansible Playbooks**: MUST use `hosts: localhost`, `connection: local`, `become: yes`
- **AWS Resources**: Tag all resources properly (Environment, Role, ManagedBy)
- **State References**: Use remote state for cross-layer references

### Testing Locally
- **Terraform**: `tofu validate`, `tofu fmt`, `tofu plan`
- **Ansible**: `ansible-playbook --syntax-check`, `ansible-lint`

### Communication
- Tag @dennisvriend in commit messages if clarification needed
- Document assumptions in code comments
- Create TODO comments for items needing human review

---

## Timeline Estimates

- **Job 1**: 4-6 hours (6 tasks)
- **Job 2**: 2-3 hours (4 tasks)
- **Job 3**: 3-4 hours (5 tasks)
- **Job 4**: 4-5 hours (6 tasks)
- **Job 5**: 1-2 hours (2 tasks)

**Total Estimated Time**: 14-20 hours of ZAI worker time

**With Parallelization**: ~8-12 hours calendar time

---

## Success Criteria

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

---

## Notes

- Each job creates a git worktree for isolated development
- All tasks use the ZAI profile (Z.AI API)
- Tasks have `commit_on_success: true` enabled
- All prompts reference the detailed task breakdown in `./references/todo.md`
- Workers should read the plan file for comprehensive context

---

Generated: 2026-01-04
