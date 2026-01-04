#!/bin/bash
# Test web servers (Nginx) - HTTP connectivity and content validation
# Usage: ./test-web-servers.sh

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
echo -e "${BLUE}Web Server Testing (Nginx)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if required commands are available
for cmd in aws jq curl; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}ERROR: $cmd is not installed${NC}"
        exit 1
    fi
done

echo -e "${YELLOW}Finding web server instances...${NC}"
echo ""

# Get web server instances from EC2
WEB_INSTANCES=$(aws ec2 describe-instances \
    --region "${AWS_REGION}" \
    --filters "Name=tag:Role,Values=web" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress,PrivateIpAddress]" \
    --output json)

WEB_COUNT=$(echo "${WEB_INSTANCES}" | jq -r 'flatten | length / 3' | awk '{print int($1)}')

if [ "${WEB_COUNT}" -eq 0 ]; then
    echo -e "${RED}ERROR: No running web server instances found${NC}"
    echo -e "${YELLOW}Expected: 2 web servers with Role=web tag${NC}"
    exit 1
fi

echo -e "${GREEN}Found ${WEB_COUNT} web server(s)${NC}"
echo ""

# Extract IPs
PUBLIC_IPS=$(echo "${WEB_INSTANCES}" | jq -r 'flatten | .[1::3] | .[]' | grep -v null || echo "")
INSTANCE_IDS=$(echo "${WEB_INSTANCES}" | jq -r 'flatten | .[0::3] | .[]')

if [ -z "${PUBLIC_IPS}" ]; then
    echo -e "${RED}ERROR: No public IPs found for web servers${NC}"
    echo -e "${YELLOW}Web servers might not have public IPs assigned${NC}"
    exit 1
fi

# Display web servers
echo -e "${BLUE}Web Server List:${NC}"
INDEX=1
for IP in ${PUBLIC_IPS}; do
    INSTANCE_ID=$(echo "${INSTANCE_IDS}" | sed -n "${INDEX}p")
    echo "  ${INDEX}. ${INSTANCE_ID} - ${IP}"
    INDEX=$((INDEX + 1))
done
echo ""

# Test each web server
echo -e "${BLUE}Testing web servers...${NC}"
echo ""

SUCCESS_COUNT=0
FAILED_COUNT=0

for IP in ${PUBLIC_IPS}; do
    echo -e "${YELLOW}Testing ${IP}...${NC}"

    # Test HTTP connectivity
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "http://${IP}" || echo "000")

    if [ "${HTTP_CODE}" = "200" ]; then
        echo -e "  ${GREEN}✓${NC} HTTP Status: ${HTTP_CODE} (OK)"

        # Get response content
        RESPONSE=$(curl -s --connect-timeout 5 --max-time 10 "http://${IP}" || echo "")

        # Check for expected content
        if echo "${RESPONSE}" | grep -q "SSM.*Ansible\|Welcome\|study-ssm-ansible"; then
            echo -e "  ${GREEN}✓${NC} Content validation: PASSED"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))

            # Show snippet of response
            echo "  Response preview:"
            echo "${RESPONSE}" | head -5 | sed 's/^/    /'
        else
            echo -e "  ${YELLOW}⚠${NC} Content validation: Unexpected content"
            echo "  Response preview:"
            echo "${RESPONSE}" | head -5 | sed 's/^/    /'
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi

        # Check response headers
        HEADERS=$(curl -s -I --connect-timeout 5 --max-time 10 "http://${IP}" || echo "")
        SERVER=$(echo "${HEADERS}" | grep -i "^Server:" | awk '{print $2}' | tr -d '\r' || echo "Unknown")
        echo "  Server: ${SERVER}"

    elif [ "${HTTP_CODE}" = "000" ]; then
        echo -e "  ${RED}✗${NC} Connection failed (timeout or refused)"
        echo "  Possible issues:"
        echo "    - Security group not allowing HTTP (port 80)"
        echo "    - Nginx not running"
        echo "    - Instance not fully configured yet"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    else
        echo -e "  ${YELLOW}⚠${NC} HTTP Status: ${HTTP_CODE}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
    echo ""
done

# Test connectivity from multiple endpoints
echo -e "${BLUE}Additional Connectivity Tests:${NC}"
echo ""

FIRST_IP=$(echo "${PUBLIC_IPS}" | head -1)
echo "Testing various HTTP methods on ${FIRST_IP}..."

# HEAD request
HEAD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -I --connect-timeout 5 "http://${FIRST_IP}" || echo "000")
echo "  HEAD request: ${HEAD_STATUS}"

# Check if HTTPS redirect exists
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://${FIRST_IP}" || echo "000")
if [ "${HTTPS_STATUS}" != "000" ]; then
    echo "  HTTPS: ${HTTPS_STATUS} (configured)"
else
    echo "  HTTPS: Not configured (expected for study project)"
fi

# Response time
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" --connect-timeout 5 "http://${FIRST_IP}" || echo "N/A")
echo "  Response time: ${RESPONSE_TIME}s"

echo ""

# Summary
echo -e "${BLUE}Test Summary:${NC}"
echo "  Total Web Servers: ${WEB_COUNT}"
echo "  Successful Tests: ${SUCCESS_COUNT}"
echo "  Failed Tests: ${FAILED_COUNT}"
echo ""

# Overall status
if [ "${SUCCESS_COUNT}" -eq "${WEB_COUNT}" ] && [ "${FAILED_COUNT}" -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Web server testing PASSED${NC}"
    echo -e "${GREEN}All web servers responding correctly${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}Web servers accessible at:${NC}"
    for IP in ${PUBLIC_IPS}; do
        echo "  http://${IP}"
    done
    echo ""
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ Web server testing FAILED${NC}"
    echo -e "${RED}${FAILED_COUNT} web server(s) not responding${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${BLUE}Troubleshooting steps:${NC}"
    echo "  1. Check if Nginx is running:"
    echo "     make ssm-session  # Connect and run: sudo systemctl status nginx"
    echo ""
    echo "  2. Check security group rules:"
    echo "     aws ec2 describe-security-groups --group-ids \$(terraform output -raw web_security_group_id)"
    echo ""
    echo "  3. Check SSM association execution:"
    echo "     ./scripts/check-ssm-associations.sh"
    echo ""
    exit 1
fi
