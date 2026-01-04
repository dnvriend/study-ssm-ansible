#!/bin/bash
# Plan all layers in order
# Usage: ./plan-all.sh [environment]
# Example: ./plan-all.sh dev

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/util.sh"

ENVIRONMENT="${1:-${ENVIRONMENT:-dev}}"

log_info "Planning all layers for environment: ${ENVIRONMENT}"

# Create plans directory
mkdir -p "${PLANS_DIR}"

# Plan each layer in order
for layer in "${LAYER_ORDER[@]}"; do
    layer_dir="${LAYERS_DIR}/${layer}"

    if [[ ! -d "${layer_dir}" ]]; then
        log_warn "Layer directory not found: ${layer_dir}, skipping"
        continue
    fi

    gitlab_section_start "plan_${layer}" "Planning ${layer}"

    # Initialize
    tf_init "${layer_dir}"

    # Select workspace
    tf_workspace_select "${ENVIRONMENT}"

    # Plan and save
    plan_file="${PLANS_DIR}/${layer}.tfplan"
    tf_plan "${layer_dir}" "${plan_file}"

    gitlab_section_end "plan_${layer}"
done

log_success "All layers planned successfully"
