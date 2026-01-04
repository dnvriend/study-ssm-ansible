#!/bin/bash
# Upload GitHub Personal Access Token to AWS Parameter Store
# Usage: ./upload-github-token.sh <github-token>
#   or: ./upload-github-token.sh  (will prompt for token)

set -euo pipefail

# Configuration
AWS_REGION="${AWS_REGION:-eu-central-1}"
PARAM_NAME="/study-ssm-ansible/github/token"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Upload GitHub Token to Parameter Store${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo -e "${RED}ERROR: AWS CLI is not installed${NC}"
    exit 1
fi

# Get token from argument or prompt
if [ $# -eq 1 ]; then
    GITHUB_TOKEN="$1"
else
    echo -e "${YELLOW}Enter GitHub Personal Access Token:${NC}"
    read -s GITHUB_TOKEN
    echo ""
fi

# Validate token format (should start with ghp_ or github_pat_)
if [[ ! "${GITHUB_TOKEN}" =~ ^(ghp_|github_pat_) ]]; then
    echo -e "${YELLOW}WARNING: Token doesn't match expected format (ghp_* or github_pat_*)${NC}"
    echo -e "${YELLOW}Are you sure this is a valid GitHub PAT?${NC}"
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted"
        exit 1
    fi
fi

echo -e "${YELLOW}Uploading token to Parameter Store...${NC}"
echo "  Parameter Name: ${PARAM_NAME}"
echo "  Region: ${AWS_REGION}"
echo ""

# Check if parameter already exists
EXISTING=$(aws ssm get-parameter \
    --name "${PARAM_NAME}" \
    --region "${AWS_REGION}" \
    --output json 2>/dev/null || echo '{}')

if [ "$(echo "${EXISTING}" | jq -r '.Parameter.Name // ""')" = "${PARAM_NAME}" ]; then
    echo -e "${YELLOW}Parameter already exists!${NC}"
    echo -e "${YELLOW}This will OVERWRITE the existing token.${NC}"
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted"
        exit 1
    fi

    # Put parameter with overwrite
    RESULT=$(aws ssm put-parameter \
        --name "${PARAM_NAME}" \
        --value "${GITHUB_TOKEN}" \
        --type "SecureString" \
        --overwrite \
        --region "${AWS_REGION}" \
        --output json)
else
    # Put new parameter
    RESULT=$(aws ssm put-parameter \
        --name "${PARAM_NAME}" \
        --value "${GITHUB_TOKEN}" \
        --type "SecureString" \
        --region "${AWS_REGION}" \
        --output json)
fi

if [ $? -eq 0 ]; then
    VERSION=$(echo "${RESULT}" | jq -r '.Version')
    echo ""
    echo -e "${GREEN}✓ Token uploaded successfully${NC}"
    echo "  Version: ${VERSION}"
    echo ""

    # Verify the parameter
    echo -e "${YELLOW}Verifying parameter...${NC}"
    VERIFY=$(aws ssm get-parameter \
        --name "${PARAM_NAME}" \
        --region "${AWS_REGION}" \
        --query "Parameter.[Name,Type,LastModifiedDate,Version]" \
        --output table)

    echo "${VERIFY}"
    echo ""

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ GitHub token upload complete${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Verify associations can access the token"
    echo "  2. Test manual association execution:"
    echo "     make ssm-trigger ENV=sandbox"
    echo ""
else
    echo ""
    echo -e "${RED}✗ Failed to upload token${NC}"
    echo "${RESULT}"
    exit 1
fi
