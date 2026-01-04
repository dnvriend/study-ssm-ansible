#!/bin/bash
# Main validation orchestrator - Run all deployment validation checks
# Usage: ./validate-deployment.sh [--quick|--full]

set -euo pipefail

# Configuration
AWS_REGION="${AWS_REGION:-eu-central-1}"
MODE="${1:---full}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BOLD}${BLUE}========================================${NC}"
echo -e "${BOLD}${BLUE}SSM + Ansible Deployment Validation${NC}"
echo -e "${BOLD}${BLUE}========================================${NC}"
echo ""
echo "Environment: sandbox"
echo "Region: ${AWS_REGION}"
echo "Mode: ${MODE}"
echo ""

# Track results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
SKIPPED_CHECKS=0

# Run a validation check
run_check() {
    local name="$1"
    local script="$2"
    local required="${3:-true}"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    echo ""
    echo -e "${BOLD}${BLUE}[CHECK ${TOTAL_CHECKS}] ${name}${NC}"
    echo -e "${BLUE}────────────────────────────────────────${NC}"

    if [ ! -f "${SCRIPT_DIR}/${script}" ]; then
        echo -e "${RED}✗ Script not found: ${script}${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi

    if bash "${SCRIPT_DIR}/${script}"; then
        echo -e "${GREEN}✓ ${name} PASSED${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        if [ "${required}" = "true" ]; then
            echo -e "${RED}✗ ${name} FAILED${NC}"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            return 1
        else
            echo -e "${YELLOW}⚠ ${name} FAILED (non-critical)${NC}"
            SKIPPED_CHECKS=$((SKIPPED_CHECKS + 1))
            return 0
        fi
    fi
}

# Start validation
echo -e "${YELLOW}Starting validation checks...${NC}"
echo ""

# Critical infrastructure checks
echo -e "${BOLD}${BLUE}=== INFRASTRUCTURE CHECKS ===${NC}"

run_check "SSM Fleet Manager" "check-ssm-fleet.sh" true
run_check "Parameter Store" "check-parameter-store.sh" true

if [ "${MODE}" = "--full" ]; then
    run_check "SSM State Manager Associations" "check-ssm-associations.sh" true
    run_check "S3 Log Bucket" "check-s3-logs.sh" false
fi

# Application checks
if [ "${MODE}" = "--full" ]; then
    echo ""
    echo -e "${BOLD}${BLUE}=== APPLICATION CHECKS ===${NC}"

    run_check "Web Servers (Nginx)" "test-web-servers.sh" true
    run_check "App Servers (Flask)" "test-app-servers.sh" true
fi

# Final summary
echo ""
echo ""
echo -e "${BOLD}${BLUE}========================================${NC}"
echo -e "${BOLD}${BLUE}VALIDATION SUMMARY${NC}"
echo -e "${BOLD}${BLUE}========================================${NC}"
echo ""

echo -e "${BLUE}Mode:${NC} ${MODE}"
echo ""
echo -e "${BLUE}Results:${NC}"
echo -e "  Total Checks:   ${TOTAL_CHECKS}"
echo -e "  ${GREEN}✓ Passed:${NC}       ${PASSED_CHECKS}"
echo -e "  ${RED}✗ Failed:${NC}       ${FAILED_CHECKS}"
echo -e "  ${YELLOW}⚠ Skipped:${NC}      ${SKIPPED_CHECKS}"
echo ""

# Calculate percentage
if [ "${TOTAL_CHECKS}" -gt 0 ]; then
    SUCCESS_RATE=$(awk "BEGIN {printf \"%.0f\", (${PASSED_CHECKS}/${TOTAL_CHECKS})*100}")
    echo "Success Rate: ${SUCCESS_RATE}%"
    echo ""
fi

# Overall status
if [ "${FAILED_CHECKS}" -eq 0 ]; then
    echo -e "${BOLD}${GREEN}========================================${NC}"
    echo -e "${BOLD}${GREEN}✓✓✓ DEPLOYMENT VALIDATION PASSED ✓✓✓${NC}"
    echo -e "${BOLD}${GREEN}========================================${NC}"
    echo ""

    if [ "${MODE}" = "--quick" ]; then
        echo -e "${BLUE}Quick validation completed successfully.${NC}"
        echo -e "${BLUE}Run with --full flag for comprehensive testing:${NC}"
        echo "  ./scripts/validate-deployment.sh --full"
        echo ""
    else
        echo -e "${GREEN}All systems operational!${NC}"
        echo ""
        echo -e "${BLUE}Your SSM + Ansible infrastructure is ready.${NC}"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "  • Test configuration drift:"
        echo "    1. Connect to a server: make ssm-session"
        echo "    2. Modify a config file"
        echo "    3. Wait 30 minutes"
        echo "    4. Verify SSM restored the config"
        echo ""
        echo "  • Update Ansible playbooks:"
        echo "    1. Modify ansible/playbooks/*.yml"
        echo "    2. Commit and push to GitHub"
        echo "    3. Wait for next association run (or trigger manually)"
        echo "    4. Verify changes applied"
        echo ""
        echo "  • Monitor associations:"
        echo "    ./scripts/check-ssm-associations.sh"
        echo ""
    fi

    exit 0
else
    echo -e "${BOLD}${RED}========================================${NC}"
    echo -e "${BOLD}${RED}✗✗✗ DEPLOYMENT VALIDATION FAILED ✗✗✗${NC}"
    echo -e "${BOLD}${RED}========================================${NC}"
    echo ""

    echo -e "${RED}${FAILED_CHECKS} check(s) failed.${NC}"
    echo ""

    echo -e "${BLUE}Common issues and solutions:${NC}"
    echo ""

    echo "1. SSM Fleet issues:"
    echo "   • Wait 2-3 minutes after instance launch for SSM agent registration"
    echo "   • Verify IAM instance profile is attached to EC2 instances"
    echo "   • Check internet connectivity (instances need to reach SSM endpoints)"
    echo ""

    echo "2. Parameter Store issues:"
    echo "   • Upload GitHub token:"
    echo "     ./scripts/upload-github-token.sh"
    echo "   • Verify 150-ssm layer was deployed successfully"
    echo ""

    echo "3. Association execution issues:"
    echo "   • Associations run every 30 minutes by default"
    echo "   • Trigger manually: make ssm-trigger ENV=sandbox"
    echo "   • Check S3 logs: ./scripts/check-s3-logs.sh"
    echo ""

    echo "4. Application issues:"
    echo "   • Verify associations executed successfully"
    echo "   • Check SSM association logs in S3"
    echo "   • Connect via Session Manager to debug:"
    echo "     make ssm-session"
    echo ""

    echo -e "${BLUE}For detailed troubleshooting, see:${NC}"
    echo "  ./references/steps-after-deploy-terraform-for-ssm-ansible.md"
    echo ""

    exit 1
fi
