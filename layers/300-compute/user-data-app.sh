#!/bin/bash
# User data script for application servers
# Sets hostname and ensures SSM agent is running
# Application configuration is managed by Ansible via SSM

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

# Create a marker file for debugging
echo "Instance initialized: $(date)" > /var/log/ssm-ansible-init.log
echo "Instance name: $INSTANCE_NAME" >> /var/log/ssm-ansible-init.log

# Note: All application configuration (Python, Flask, etc.) is managed
# by Ansible playbooks executed via SSM State Manager associations
