#!/bin/bash
# Pipeline variables
# This file is sourced by other pipeline scripts

set -euo pipefail

# Script directory
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPTS_DIR}/.."
LAYERS_DIR="${REPO_ROOT}/layers"
PLANS_DIR="${REPO_ROOT}/plans"

# AWS Configuration
AWS_REGION="${AWS_REGION:-eu-central-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-123456789012}"

# OpenTofu Configuration
TF_STATE_BUCKET="${AWS_ACCOUNT_ID}-tf-state"
TF_LOCK_TABLE="terraform_lock_${AWS_ACCOUNT_ID}"

# Environment (default to dev)
ENVIRONMENT="${ENVIRONMENT:-dev}"

# Layer order for sequential deployment
LAYER_ORDER=(
    "100-network"
    "150-ssm"
    "200-iam"
    "300-compute"
    "400-data"
    "500-application"
    "600-dns"
    "700-lambda"
)

export AWS_REGION AWS_ACCOUNT_ID TF_STATE_BUCKET TF_LOCK_TABLE ENVIRONMENT
export SCRIPTS_DIR REPO_ROOT LAYERS_DIR PLANS_DIR LAYER_ORDER
