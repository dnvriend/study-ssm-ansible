#!/bin/bash
# Check SSM State Manager Associations - Validate associations and execution status
# Usage: ./check-ssm-associations.sh

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
echo -e "${BLUE}SSM State Manager Associations${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo -e "${RED}ERROR: AWS CLI is not installed${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking SSM associations...${NC}"
echo ""

# List all associations
ASSOCIATIONS=$(aws ssm list-associations \
    --region "${AWS_REGION}" \
    --output json 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to query SSM associations${NC}"
    echo "${ASSOCIATIONS}"
    exit 1
fi

# Count associations
TOTAL_ASSOC=$(echo "${ASSOCIATIONS}" | jq -r '.Associations | length')

if [ "${TOTAL_ASSOC}" -eq 0 ]; then
    echo -e "${RED}ERROR: No associations found${NC}"
    echo -e "${YELLOW}Expected associations:${NC}"
    echo "  - study-ssm-ansible-common"
    echo "  - study-ssm-ansible-web"
    echo "  - study-ssm-ansible-app"
    echo "  - study-ssm-ansible-bastion"
    exit 1
fi

echo -e "${GREEN}Found ${TOTAL_ASSOC} association(s)${NC}"
echo ""

# Display association details
echo -e "${BLUE}Association List:${NC}"
echo ""
aws ssm list-associations \
    --region "${AWS_REGION}" \
    --query "Associations[*].[Name,AssociationId,AssociationName,ScheduleExpression,LastExecutionDate]" \
    --output table

echo ""

# Check each association status
echo -e "${BLUE}Checking association execution status...${NC}"
echo ""

FAILED_ASSOC=0
SUCCESS_ASSOC=0

for ASSOC_ID in $(echo "${ASSOCIATIONS}" | jq -r '.Associations[].AssociationId'); do
    ASSOC_NAME=$(echo "${ASSOCIATIONS}" | jq -r ".Associations[] | select(.AssociationId==\"${ASSOC_ID}\") | .AssociationName")

    # Get association details
    ASSOC_DETAIL=$(aws ssm describe-association \
        --association-id "${ASSOC_ID}" \
        --region "${AWS_REGION}" \
        --output json 2>/dev/null || echo '{}')

    STATUS=$(echo "${ASSOC_DETAIL}" | jq -r '.AssociationDescription.Status.Name // "Unknown"')
    LAST_EXEC=$(echo "${ASSOC_DETAIL}" | jq -r '.AssociationDescription.LastExecutionDate // "Never"')

    # Get recent executions
    EXECUTIONS=$(aws ssm list-association-executions \
        --association-id "${ASSOC_ID}" \
        --region "${AWS_REGION}" \
        --max-results 5 \
        --output json 2>/dev/null || echo '{"AssociationExecutions":[]}')

    EXEC_COUNT=$(echo "${EXECUTIONS}" | jq -r '.AssociationExecutions | length')
    LATEST_STATUS=$(echo "${EXECUTIONS}" | jq -r '.AssociationExecutions[0].Status // "None"')

    echo -e "${BLUE}Association:${NC} ${ASSOC_NAME}"
    echo "  ID: ${ASSOC_ID}"
    echo "  Overall Status: ${STATUS}"
    echo "  Last Execution: ${LAST_EXEC}"
    echo "  Recent Execution Status: ${LATEST_STATUS}"
    echo "  Total Executions: ${EXEC_COUNT}"

    # Check if latest execution was successful
    if [ "${LATEST_STATUS}" = "Success" ]; then
        echo -e "  ${GREEN}✓ Latest execution succeeded${NC}"
        SUCCESS_ASSOC=$((SUCCESS_ASSOC + 1))
    elif [ "${LATEST_STATUS}" = "Failed" ]; then
        echo -e "  ${RED}✗ Latest execution failed${NC}"
        FAILED_ASSOC=$((FAILED_ASSOC + 1))

        # Show failure details
        echo ""
        echo -e "  ${YELLOW}Recent failed executions:${NC}"
        aws ssm list-association-executions \
            --association-id "${ASSOC_ID}" \
            --region "${AWS_REGION}" \
            --filters "Key=Status,Values=Failed" \
            --max-results 3 \
            --query "AssociationExecutions[*].[ExecutionId,Status,DetailedStatus,CreatedTime]" \
            --output table | sed 's/^/    /'
    elif [ "${LATEST_STATUS}" = "InProgress" ]; then
        echo -e "  ${YELLOW}⏳ Execution in progress${NC}"
    elif [ "${LATEST_STATUS}" = "None" ] || [ "${EXEC_COUNT}" -eq 0 ]; then
        echo -e "  ${YELLOW}⚠ No executions yet (associations run every 30 minutes)${NC}"
    fi

    echo ""
done

# Display expected associations
EXPECTED_ASSOC=("common" "web" "app" "bastion")
echo -e "${BLUE}Expected Associations:${NC}"
for EXPECTED in "${EXPECTED_ASSOC[@]}"; do
    FOUND=$(echo "${ASSOCIATIONS}" | jq -r ".Associations[] | select(.AssociationName | contains(\"${EXPECTED}\")) | .AssociationName" || echo "")
    if [ -n "${FOUND}" ]; then
        echo -e "  ${GREEN}✓${NC} study-ssm-ansible-${EXPECTED}"
    else
        echo -e "  ${RED}✗${NC} study-ssm-ansible-${EXPECTED} (NOT FOUND)"
    fi
done
echo ""

# Summary
echo -e "${BLUE}Execution Summary:${NC}"
echo "  Total Associations: ${TOTAL_ASSOC}"
echo "  Successful Executions: ${SUCCESS_ASSOC}"
echo "  Failed Executions: ${FAILED_ASSOC}"
echo ""

# Overall status
EXPECTED_COUNT=4
if [ "${TOTAL_ASSOC}" -eq "${EXPECTED_COUNT}" ] && [ "${FAILED_ASSOC}" -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ SSM State Manager validation PASSED${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
elif [ "${TOTAL_ASSOC}" -lt "${EXPECTED_COUNT}" ]; then
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}⚠ Missing associations${NC}"
    echo -e "${YELLOW}Expected ${EXPECTED_COUNT}, found ${TOTAL_ASSOC}${NC}"
    echo -e "${YELLOW}========================================${NC}"
    exit 1
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ SSM State Manager validation FAILED${NC}"
    echo -e "${RED}${FAILED_ASSOC} association(s) have failures${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
