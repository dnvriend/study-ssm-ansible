#!/bin/bash
# Destroy all layers in reverse order
# Usage: ./destroy-all.sh [environment]
# Example: ./destroy-all.sh dev

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/util.sh"

ENVIRONMENT="${1:-${ENVIRONMENT:-dev}}"

log_warn "This will destroy ALL resources in ALL layers for environment: ${ENVIRONMENT}"
log_warn "Layers will be destroyed in reverse order:"
for (( i=${#LAYER_ORDER[@]}-1; i>=0; i-- )); do
    echo "  - ${LAYER_ORDER[$i]}"
done

read -p "Are you sure? (yes/no): " confirm

if [[ "${confirm}" != "yes" ]]; then
    log_info "Aborted"
    exit 0
fi

# Destroy each layer in reverse order
for (( i=${#LAYER_ORDER[@]}-1; i>=0; i-- )); do
    layer="${LAYER_ORDER[$i]}"
    layer_dir="${LAYERS_DIR}/${layer}"

    if [[ ! -d "${layer_dir}" ]]; then
        log_warn "Layer directory not found: ${layer_dir}, skipping"
        continue
    fi

    gitlab_section_start "destroy_${layer}" "Destroying ${layer}"

    # Initialize
    tf_init "${layer_dir}"

    # Select workspace
    tf_workspace_select "${ENVIRONMENT}"

    # Destroy (force, no confirmation since we already confirmed)
    cd "${layer_dir}"
    local var_file="${layer_dir}/envs/${ENVIRONMENT}.tfvars"
    local destroy_args=("-auto-approve")
    if [[ -f "${var_file}" ]]; then
        destroy_args+=("-var-file=${var_file}")
    fi
    tofu destroy "${destroy_args[@]}" || log_warn "Destroy failed for ${layer}, continuing..."

    gitlab_section_end "destroy_${layer}"
done

log_success "All layers destroyed"

