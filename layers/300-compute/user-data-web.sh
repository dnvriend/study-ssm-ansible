#!/bin/bash
# User data script for web servers
# This script sets up the base configuration - Ansible handles the rest

set -e

INSTANCE_NAME="${instance_name}"

# Set hostname
hostnamectl set-hostname "$INSTANCE_NAME"

# Update hostname in /etc/hosts
echo "127.0.0.1 $INSTANCE_NAME" >> /etc/hosts

# Ensure SSM agent is running and enabled
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Basic system updates
yum update -y

# Install basic packages (Ansible will handle the rest)
yum install -y git curl wget jq python3 python3-pip

# Note: All application configuration (Nginx, monitoring, etc.)
# is handled by Ansible playbooks via SSM State Manager
