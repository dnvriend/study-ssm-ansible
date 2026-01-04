#!/bin/bash
# Check S3 bucket for SSM association logs
# Usage: ./check-s3-logs.sh [association-type]
#   association-type: common, web, app, bastion, or all (default)

set -euo pipefail

# Configuration
AWS_REGION="${AWS_REGION:-eu-central-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-862378407079}"
S3_BUCKET="study-ssm-ansible-logs-${AWS_ACCOUNT_ID}"
ASSOC_TYPE="${1:-all}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}S3 Association Logs Validation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo -e "${RED}ERROR: AWS CLI is not installed${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking S3 bucket: ${S3_BUCKET}${NC}"
echo ""

# Check if bucket exists
BUCKET_EXISTS=$(aws s3 ls s3://"${S3_BUCKET}" 2>&1 || echo "ERROR")

if [[ "${BUCKET_EXISTS}" =~ "ERROR" ]] || [[ "${BUCKET_EXISTS}" =~ "NoSuchBucket" ]]; then
    echo -e "${RED}ERROR: S3 bucket does not exist${NC}"
    echo "  Bucket: s3://${S3_BUCKET}"
    echo ""
    echo -e "${YELLOW}Bucket should be created by 150-ssm layer${NC}"
    exit 1
fi

echo -e "${GREEN}✓ S3 bucket exists${NC}"
echo ""

# Check bucket lifecycle configuration
echo -e "${BLUE}Checking bucket lifecycle...${NC}"
LIFECYCLE=$(aws s3api get-bucket-lifecycle-configuration \
    --bucket "${S3_BUCKET}" \
    --region "${AWS_REGION}" \
    --output json 2>/dev/null || echo '{}')

if [ "$(echo "${LIFECYCLE}" | jq -r '.Rules | length')" -gt 0 ]; then
    EXPIRATION=$(echo "${LIFECYCLE}" | jq -r '.Rules[0].Expiration.Days // "N/A"')
    echo -e "  ${GREEN}✓${NC} Lifecycle configured: Logs expire after ${EXPIRATION} days"
else
    echo -e "  ${YELLOW}⚠${NC} No lifecycle policy found"
fi
echo ""

# List association logs
echo -e "${BLUE}Association Logs:${NC}"
echo ""

if [ "${ASSOC_TYPE}" = "all" ]; then
    ASSOC_TYPES=("common" "web" "app" "bastion")
else
    ASSOC_TYPES=("${ASSOC_TYPE}")
fi

TOTAL_LOGS=0
for TYPE in "${ASSOC_TYPES[@]}"; do
    echo -e "${YELLOW}Checking ${TYPE} association logs...${NC}"

    LOGS=$(aws s3 ls s3://"${S3_BUCKET}"/associations/"${TYPE}"/ --recursive 2>/dev/null || echo "")

    if [ -z "${LOGS}" ]; then
        echo -e "  ${YELLOW}⚠${NC} No logs found for ${TYPE} association"
        echo "    (Associations may not have run yet - they execute every 30 minutes)"
    else
        LOG_COUNT=$(echo "${LOGS}" | wc -l | tr -d ' ')
        echo -e "  ${GREEN}✓${NC} Found ${LOG_COUNT} log file(s) for ${TYPE}"

        # Show most recent logs
        echo ""
        echo "  Recent logs:"
        echo "${LOGS}" | tail -5 | awk '{print "    " $0}'

        TOTAL_LOGS=$((TOTAL_LOGS + LOG_COUNT))
    fi
    echo ""
done

# Check recent log content
if [ "${TOTAL_LOGS}" -gt 0 ]; then
    echo -e "${BLUE}Sample Log Content:${NC}"
    echo ""

    # Get the most recent log file
    RECENT_LOG=$(aws s3 ls s3://"${S3_BUCKET}"/associations/ --recursive | sort | tail -1 | awk '{print $4}')

    if [ -n "${RECENT_LOG}" ]; then
        echo "  Most recent log: ${RECENT_LOG}"
        echo ""
        echo "  To view full log:"
        echo "    aws s3 cp s3://${S3_BUCKET}/${RECENT_LOG} -"
        echo ""

        # Show first few lines
        echo "  Preview (first 20 lines):"
        aws s3 cp s3://"${S3_BUCKET}"/"${RECENT_LOG}" - 2>/dev/null | head -20 | sed 's/^/    /' || echo "    Unable to read log"
    fi
fi
echo ""

# Summary
echo -e "${BLUE}Summary:${NC}"
echo "  S3 Bucket: s3://${S3_BUCKET}"
echo "  Total Log Files: ${TOTAL_LOGS}"
echo ""

# Overall status
if [ "${TOTAL_LOGS}" -gt 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ S3 logs validation PASSED${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}Useful commands:${NC}"
    echo "  # List all logs"
    echo "  aws s3 ls s3://${S3_BUCKET}/associations/ --recursive"
    echo ""
    echo "  # Download specific log"
    echo "  aws s3 cp s3://${S3_BUCKET}/associations/common/xxxxx/stdout /tmp/log.txt"
    echo ""
    echo "  # View log directly"
    echo "  aws s3 cp s3://${S3_BUCKET}/associations/common/xxxxx/stdout -"
    echo ""
    exit 0
else
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}⚠ S3 logs validation: No logs yet${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo -e "${BLUE}This is normal if:${NC}"
    echo "  - Associations were just created"
    echo "  - Associations haven't run yet (schedule: every 30 minutes)"
    echo "  - No manual association triggers have been executed"
    echo ""
    echo -e "${BLUE}To trigger associations manually:${NC}"
    echo "  make ssm-trigger ENV=sandbox"
    echo ""
    exit 0
fi
