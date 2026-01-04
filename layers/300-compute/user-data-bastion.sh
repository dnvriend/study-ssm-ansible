#!/bin/bash
# User data script for bastion host
# Sets hostname and ensures SSM agent is running

set -e

INSTANCE_NAME="${instance_name}"

# Set hostname
hostnamectl set-hostname "$INSTANCE_NAME"

# Update /etc/hosts
echo "127.0.0.1 $INSTANCE_NAME" >> /etc/hosts

# Ensure SSM agent is enabled and running
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Basic system updates (minimal - Ansible handles the rest)
yum update -y --security

# Install additional bastion-specific tools
yum install -y tmux htop tree

# Create a marker file for debugging
echo "Bastion initialized: $(date)" > /var/log/ssm-ansible-init.log
echo "Instance name: $INSTANCE_NAME" >> /var/log/ssm-ansible-init.log

# Note: SSH hardening and additional security configurations
# are managed by Ansible playbooks executed via SSM State Manager
