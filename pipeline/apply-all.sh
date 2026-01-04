#!/bin/bash
# Apply all layers in order
# Usage: ./apply-all.sh [environment]
# Example: ./apply-all.sh dev

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/util.sh"

ENVIRONMENT="${1:-${ENVIRONMENT:-dev}}"

log_info "Applying all layers for environment: ${ENVIRONMENT}"

# Apply each layer in order
for layer in "${LAYER_ORDER[@]}"; do
    layer_dir="${LAYERS_DIR}/${layer}"

    if [[ ! -d "${layer_dir}" ]]; then
        log_warn "Layer directory not found: ${layer_dir}, skipping"
        continue
    fi

    gitlab_section_start "apply_${layer}" "Applying ${layer}"

    # Initialize
    tf_init "${layer_dir}"

    # Select workspace
    tf_workspace_select "${ENVIRONMENT}"

    # Check for saved plan
    plan_file="${PLANS_DIR}/${layer}.tfplan"
    if [[ -f "${plan_file}" ]]; then
        tf_apply "${layer_dir}" "${plan_file}"
    else
        tf_apply "${layer_dir}"
    fi

    gitlab_section_end "apply_${layer}"
done

log_success "All layers applied successfully"
