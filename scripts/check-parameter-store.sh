#!/bin/bash
# Check AWS Systems Manager Parameter Store - Validate all required parameters
# Usage: ./check-parameter-store.sh

set -euo pipefail

# Configuration
AWS_REGION="${AWS_REGION:-eu-central-1}"
PARAM_PREFIX="/study-ssm-ansible"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Parameter Store Validation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo -e "${RED}ERROR: AWS CLI is not installed${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking parameters under ${PARAM_PREFIX}...${NC}"
echo ""

# Get all parameters by path
PARAMS=$(aws ssm get-parameters-by-path \
    --path "${PARAM_PREFIX}" \
    --recursive \
    --region "${AWS_REGION}" \
    --output json 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to query Parameter Store${NC}"
    echo "${PARAMS}"
    exit 1
fi

# Count parameters
TOTAL_PARAMS=$(echo "${PARAMS}" | jq -r '.Parameters | length')

if [ "${TOTAL_PARAMS}" -eq 0 ]; then
    echo -e "${RED}ERROR: No parameters found under ${PARAM_PREFIX}${NC}"
    echo -e "${YELLOW}Expected parameters:${NC}"
    echo "  - ${PARAM_PREFIX}/github/token"
    echo "  - ${PARAM_PREFIX}/app/database_url"
    echo "  - ${PARAM_PREFIX}/app/secret_key"
    echo "  - ${PARAM_PREFIX}/nginx/worker_processes"
    echo "  - ${PARAM_PREFIX}/global/environment"
    exit 1
fi

echo -e "${GREEN}Found ${TOTAL_PARAMS} parameter(s)${NC}"
echo ""

# Display parameters (values hidden for SecureString)
echo -e "${BLUE}Parameter List:${NC}"
echo ""

aws ssm get-parameters-by-path \
    --path "${PARAM_PREFIX}" \
    --recursive \
    --region "${AWS_REGION}" \
    --query "Parameters[*].[Name,Type,LastModifiedDate]" \
    --output table

echo ""

# Check each expected parameter
echo -e "${BLUE}Checking expected parameters...${NC}"
echo ""

EXPECTED_PARAMS=(
    "${PARAM_PREFIX}/github/token:SecureString"
    "${PARAM_PREFIX}/app/database_url:String"
    "${PARAM_PREFIX}/app/secret_key:SecureString"
    "${PARAM_PREFIX}/nginx/worker_processes:String"
    "${PARAM_PREFIX}/global/environment:String"
)

MISSING=0
for PARAM_DEF in "${EXPECTED_PARAMS[@]}"; do
    PARAM_NAME="${PARAM_DEF%:*}"
    EXPECTED_TYPE="${PARAM_DEF#*:}"

    # Check if parameter exists
    FOUND=$(echo "${PARAMS}" | jq -r ".Parameters[] | select(.Name==\"${PARAM_NAME}\") | .Name" || echo "")

    if [ -n "${FOUND}" ]; then
        ACTUAL_TYPE=$(echo "${PARAMS}" | jq -r ".Parameters[] | select(.Name==\"${PARAM_NAME}\") | .Type")
        if [ "${ACTUAL_TYPE}" = "${EXPECTED_TYPE}" ]; then
            echo -e "  ${GREEN}✓${NC} ${PARAM_NAME} (${ACTUAL_TYPE})"
        else
            echo -e "  ${YELLOW}⚠${NC} ${PARAM_NAME} (Expected: ${EXPECTED_TYPE}, Found: ${ACTUAL_TYPE})"
        fi
    else
        echo -e "  ${RED}✗${NC} ${PARAM_NAME} (NOT FOUND)"
        MISSING=$((MISSING + 1))
    fi
done
echo ""

# Try to get values for non-secure parameters
echo -e "${BLUE}Parameter Values (non-secure only):${NC}"
echo ""

for PARAM_NAME in "${PARAM_PREFIX}/app/database_url" "${PARAM_PREFIX}/nginx/worker_processes" "${PARAM_PREFIX}/global/environment"; do
    VALUE=$(aws ssm get-parameter \
        --name "${PARAM_NAME}" \
        --region "${AWS_REGION}" \
        --query "Parameter.Value" \
        --output text 2>/dev/null || echo "N/A")

    SHORT_NAME="${PARAM_NAME##*/}"
    echo "  ${SHORT_NAME}: ${VALUE}"
done
echo ""

# Check GitHub token specifically
echo -e "${BLUE}Checking GitHub token...${NC}"

GITHUB_TOKEN=$(aws ssm get-parameter \
    --name "${PARAM_PREFIX}/github/token" \
    --region "${AWS_REGION}" \
    --output json 2>/dev/null || echo '{}')

if [ "$(echo "${GITHUB_TOKEN}" | jq -r '.Parameter.Name // ""')" = "${PARAM_PREFIX}/github/token" ]; then
    LAST_MODIFIED=$(echo "${GITHUB_TOKEN}" | jq -r '.Parameter.LastModifiedDate')
    VERSION=$(echo "${GITHUB_TOKEN}" | jq -r '.Parameter.Version')
    echo -e "  ${GREEN}✓${NC} GitHub token exists"
    echo "    Last Modified: ${LAST_MODIFIED}"
    echo "    Version: ${VERSION}"
else
    echo -e "  ${RED}✗${NC} GitHub token NOT FOUND"
    echo ""
    echo -e "${YELLOW}To upload GitHub token:${NC}"
    echo "  ./scripts/upload-github-token.sh"
    MISSING=$((MISSING + 1))
fi
echo ""

# Summary
EXPECTED_COUNT=${#EXPECTED_PARAMS[@]}
if [ "${MISSING}" -eq 0 ] && [ "${TOTAL_PARAMS}" -ge "${EXPECTED_COUNT}" ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Parameter Store validation PASSED${NC}"
    echo -e "${GREEN}All ${EXPECTED_COUNT} required parameters present${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ Parameter Store validation FAILED${NC}"
    echo -e "${RED}Missing ${MISSING} required parameter(s)${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
