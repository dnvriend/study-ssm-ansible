#!/bin/bash
# Test application servers (Flask) via Session Manager
# Usage: ./test-app-servers.sh

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
echo -e "${BLUE}Application Server Testing (Flask)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if required commands are available
for cmd in aws jq; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}ERROR: $cmd is not installed${NC}"
        exit 1
    fi
done

echo -e "${YELLOW}Finding application server instances...${NC}"
echo ""

# Get app server instances from EC2
APP_INSTANCES=$(aws ec2 describe-instances \
    --region "${AWS_REGION}" \
    --filters "Name=tag:Role,Values=app" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].[InstanceId,PrivateIpAddress]" \
    --output json)

APP_COUNT=$(echo "${APP_INSTANCES}" | jq -r 'flatten | length / 2' | awk '{print int($1)}')

if [ "${APP_COUNT}" -eq 0 ]; then
    echo -e "${RED}ERROR: No running app server instances found${NC}"
    echo -e "${YELLOW}Expected: 2 app servers with Role=app tag${NC}"
    exit 1
fi

echo -e "${GREEN}Found ${APP_COUNT} app server(s)${NC}"
echo ""

# Extract instance IDs and IPs - use indices to get every 2nd element starting at position 0 (InstanceID) and 1 (PrivateIP)
INSTANCE_IDS=$(echo "${APP_INSTANCES}" | jq -r '[flatten] | .[0] | to_entries | map(select(.key % 2 == 0)) | .[].value')
PRIVATE_IPS=$(echo "${APP_INSTANCES}" | jq -r '[flatten] | .[0] | to_entries | map(select(.key % 2 == 1)) | .[].value')

# Display app servers
echo -e "${BLUE}Application Server List:${NC}"
INDEX=1
while IFS= read -r INSTANCE_ID && IFS= read -r IP <&3; do
    echo "  ${INDEX}. ${INSTANCE_ID} - ${IP}"
    INDEX=$((INDEX + 1))
done < <(echo "${INSTANCE_IDS}") 3< <(echo "${PRIVATE_IPS}")
echo ""

# Check if instances are registered with SSM
echo -e "${BLUE}Checking SSM registration...${NC}"
echo ""

SUCCESS_COUNT=0
FAILED_COUNT=0
SSM_READY=0

for INSTANCE_ID in ${INSTANCE_IDS}; do
    SSM_STATUS=$(aws ssm describe-instance-information \
        --region "${AWS_REGION}" \
        --filters "Key=InstanceIds,Values=${INSTANCE_ID}" \
        --query "InstanceInformationList[0].PingStatus" \
        --output text 2>/dev/null || echo "NotFound")

    if [ "${SSM_STATUS}" = "Online" ]; then
        echo -e "  ${GREEN}✓${NC} ${INSTANCE_ID}: SSM Status = Online"
        SSM_READY=$((SSM_READY + 1))
    else
        echo -e "  ${RED}✗${NC} ${INSTANCE_ID}: SSM Status = ${SSM_STATUS}"
    fi
done
echo ""

if [ "${SSM_READY}" -eq 0 ]; then
    echo -e "${RED}ERROR: No app servers are registered with SSM${NC}"
    echo -e "${YELLOW}Cannot test app servers without SSM Session Manager${NC}"
    exit 1
fi

# Test each app server via SSM command
echo -e "${BLUE}Testing Flask application via SSM...${NC}"
echo ""

for INSTANCE_ID in ${INSTANCE_IDS}; do
    echo -e "${YELLOW}Testing ${INSTANCE_ID}...${NC}"

    # Check if Flask service is running
    echo "  Checking Flask service status..."
    CMD_OUTPUT=$(aws ssm send-command \
        --region "${AWS_REGION}" \
        --instance-ids "${INSTANCE_ID}" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["sudo systemctl is-active flask-app"]' \
        --output json)

    COMMAND_ID=$(echo "${CMD_OUTPUT}" | jq -r '.Command.CommandId')

    # Wait for command to complete
    sleep 3

    # Get command result
    RESULT=$(aws ssm get-command-invocation \
        --region "${AWS_REGION}" \
        --command-id "${COMMAND_ID}" \
        --instance-id "${INSTANCE_ID}" \
        --output json 2>/dev/null || echo '{}')

    SERVICE_STATUS=$(echo "${RESULT}" | jq -r '.StandardOutputContent' | tr -d '\n\r' || echo "unknown")
    CMD_STATUS=$(echo "${RESULT}" | jq -r '.Status' || echo "Failed")

    if [ "${SERVICE_STATUS}" = "active" ] && [ "${CMD_STATUS}" = "Success" ]; then
        echo -e "  ${GREEN}✓${NC} Flask service: active"
    else
        echo -e "  ${RED}✗${NC} Flask service: ${SERVICE_STATUS} (command: ${CMD_STATUS})"
    fi

    # Test Flask endpoint
    echo "  Testing Flask health endpoint..."
    CMD_OUTPUT=$(aws ssm send-command \
        --region "${AWS_REGION}" \
        --instance-ids "${INSTANCE_ID}" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["curl -s http://localhost:5000/health || echo FAILED"]' \
        --output json)

    COMMAND_ID=$(echo "${CMD_OUTPUT}" | jq -r '.Command.CommandId')
    sleep 3

    RESULT=$(aws ssm get-command-invocation \
        --region "${AWS_REGION}" \
        --command-id "${COMMAND_ID}" \
        --instance-id "${INSTANCE_ID}" \
        --output json 2>/dev/null || echo '{}')

    HEALTH_OUTPUT=$(echo "${RESULT}" | jq -r '.StandardOutputContent' || echo "FAILED")
    CMD_STATUS=$(echo "${RESULT}" | jq -r '.Status' || echo "Failed")

    if [ "${CMD_STATUS}" = "Success" ] && [[ ! "${HEALTH_OUTPUT}" =~ "FAILED" ]]; then
        echo -e "  ${GREEN}✓${NC} Health endpoint: responding"
        echo "    Response: $(echo "${HEALTH_OUTPUT}" | head -1)"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo -e "  ${RED}✗${NC} Health endpoint: not responding"
        echo "    Output: ${HEALTH_OUTPUT}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi

    # Get Flask logs
    echo "  Getting recent Flask logs..."
    CMD_OUTPUT=$(aws ssm send-command \
        --region "${AWS_REGION}" \
        --instance-ids "${INSTANCE_ID}" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["sudo journalctl -u flask-app -n 5 --no-pager"]' \
        --output json)

    COMMAND_ID=$(echo "${CMD_OUTPUT}" | jq -r '.Command.CommandId')
    sleep 3

    RESULT=$(aws ssm get-command-invocation \
        --region "${AWS_REGION}" \
        --command-id "${COMMAND_ID}" \
        --instance-id "${INSTANCE_ID}" \
        --output json 2>/dev/null || echo '{}')

    LOGS=$(echo "${RESULT}" | jq -r '.StandardOutputContent' || echo "No logs available")
    echo "    Recent logs:"
    echo "${LOGS}" | head -3 | sed 's/^/      /'

    echo ""
done

# Summary
echo -e "${BLUE}Test Summary:${NC}"
echo "  Total App Servers: ${APP_COUNT}"
echo "  SSM Ready: ${SSM_READY}"
echo "  Successful Tests: ${SUCCESS_COUNT}"
echo "  Failed Tests: ${FAILED_COUNT}"
echo ""

# Overall status
if [ "${SUCCESS_COUNT}" -eq "${APP_COUNT}" ] && [ "${FAILED_COUNT}" -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Application server testing PASSED${NC}"
    echo -e "${GREEN}All Flask applications responding${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}To connect to an app server:${NC}"
    echo "  make ssm-session"
    echo "  # Then enter instance ID"
    echo ""
    echo -e "${BLUE}To test Flask manually:${NC}"
    echo "  curl http://localhost:5000/health"
    echo "  curl http://localhost:5000/"
    echo ""
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ Application server testing FAILED${NC}"
    echo -e "${RED}${FAILED_COUNT} app server(s) not responding${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${BLUE}Troubleshooting steps:${NC}"
    echo "  1. Connect via Session Manager:"
    echo "     make ssm-session  # Enter app server instance ID"
    echo ""
    echo "  2. Check Flask service:"
    echo "     sudo systemctl status flask-app"
    echo "     sudo journalctl -u flask-app -n 50"
    echo ""
    echo "  3. Check if Python virtual environment exists:"
    echo "     ls -la /opt/flask-app/"
    echo ""
    echo "  4. Check SSM association execution:"
    echo "     ./scripts/check-ssm-associations.sh"
    echo ""
    exit 1
fi
