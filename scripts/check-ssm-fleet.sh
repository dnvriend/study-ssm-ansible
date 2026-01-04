#!/bin/bash
# Check SSM Fleet Manager - Validate all instances are registered and online
# Usage: ./check-ssm-fleet.sh

set -euo pipefail

# Configuration
AWS_REGION="${AWS_REGION:-eu-central-1}"
ENVIRONMENT="${ENVIRONMENT:-sandbox}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SSM Fleet Manager Validation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo -e "${RED}ERROR: AWS CLI is not installed${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking SSM managed instances...${NC}"
echo ""

# Get instance information
INSTANCES=$(aws ssm describe-instance-information \
    --region "${AWS_REGION}" \
    --output json 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to query SSM${NC}"
    echo "${INSTANCES}"
    exit 1
fi

# Count instances
TOTAL_INSTANCES=$(echo "${INSTANCES}" | jq -r '.InstanceInformationList | length')

if [ "${TOTAL_INSTANCES}" -eq 0 ]; then
    echo -e "${RED}ERROR: No instances found in SSM Fleet Manager${NC}"
    echo -e "${YELLOW}Possible reasons:${NC}"
    echo "  - Instances not launched yet"
    echo "  - SSM agent not started (wait 2-3 minutes after launch)"
    echo "  - IAM instance profile not attached"
    echo "  - Network connectivity issues"
    exit 1
fi

echo -e "${GREEN}Found ${TOTAL_INSTANCES} instance(s) in SSM Fleet${NC}"
echo ""

# Display instance details
echo -e "${BLUE}Instance Details:${NC}"
echo ""
aws ssm describe-instance-information \
    --region "${AWS_REGION}" \
    --query "InstanceInformationList[*].[InstanceId,PingStatus,PlatformName,PlatformVersion,IPAddress,AgentVersion]" \
    --output table

echo ""

# Check instance status counts
ONLINE_COUNT=$(echo "${INSTANCES}" | jq -r '[.InstanceInformationList[] | select(.PingStatus=="Online")] | length')
CONNECTION_LOST=$(echo "${INSTANCES}" | jq -r '[.InstanceInformationList[] | select(.PingStatus=="ConnectionLost")] | length')
INACTIVE=$(echo "${INSTANCES}" | jq -r '[.InstanceInformationList[] | select(.PingStatus=="Inactive")] | length')

echo -e "${BLUE}Status Summary:${NC}"
echo -e "  ${GREEN}Online:${NC}          ${ONLINE_COUNT}"
echo -e "  ${YELLOW}ConnectionLost:${NC}  ${CONNECTION_LOST}"
echo -e "  ${RED}Inactive:${NC}        ${INACTIVE}"
echo ""

# Check expected instance count (2 web + 2 app + 1 bastion = 5 for this project)
EXPECTED_COUNT=5

if [ "${TOTAL_INSTANCES}" -lt "${EXPECTED_COUNT}" ]; then
    echo -e "${YELLOW}WARNING: Expected at least ${EXPECTED_COUNT} instances, found ${TOTAL_INSTANCES}${NC}"
elif [ "${TOTAL_INSTANCES}" -gt "${EXPECTED_COUNT}" ]; then
    echo -e "${YELLOW}INFO: Found ${TOTAL_INSTANCES} instances (expected ${EXPECTED_COUNT} for this project)${NC}"
    echo -e "${YELLOW}      Additional instances may be from other projects${NC}"
fi

# Validate all instances are online
if [ "${ONLINE_COUNT}" -eq "${TOTAL_INSTANCES}" ]; then
    echo -e "${GREEN}✓ All instances are ONLINE${NC}"
    echo ""

    # Check instance tags via EC2 (SSM tags are the same as EC2 tags)
    echo -e "${BLUE}Checking instance tags...${NC}"
    echo ""

    for INSTANCE_ID in $(echo "${INSTANCES}" | jq -r '.InstanceInformationList[].InstanceId'); do
        TAGS=$(aws ec2 describe-tags \
            --filters "Name=resource-id,Values=${INSTANCE_ID}" \
            --region "${AWS_REGION}" \
            --output json 2>/dev/null || echo '{"Tags":[]}')

        ROLE_TAG=$(echo "${TAGS}" | jq -r '.Tags[] | select(.Key=="Role") | .Value' || echo "N/A")
        ENV_TAG=$(echo "${TAGS}" | jq -r '.Tags[] | select(.Key=="Environment") | .Value' || echo "N/A")
        NAME_TAG=$(echo "${TAGS}" | jq -r '.Tags[] | select(.Key=="Name") | .Value' || echo "N/A")

        echo "  ${INSTANCE_ID}: Name=${NAME_TAG}, Role=${ROLE_TAG}, Env=${ENV_TAG}"
    done
    echo ""

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ SSM Fleet validation PASSED${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}✗ Some instances are not ONLINE${NC}"
    echo ""
    echo -e "${YELLOW}Instances with issues:${NC}"
    aws ssm describe-instance-information \
        --region "${AWS_REGION}" \
        --filters "Key=PingStatus,Values=ConnectionLost,Inactive" \
        --query "InstanceInformationList[*].[InstanceId,PingStatus,LastPingDateTime]" \
        --output table

    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ SSM Fleet validation FAILED${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
