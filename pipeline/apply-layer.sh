#!/bin/bash
# Apply a single layer
# Usage: ./apply-layer.sh <layer-name> [environment]
# Example: ./apply-layer.sh 100-network dev

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/util.sh"

LAYER="${1:-}"
ENVIRONMENT="${2:-${ENVIRONMENT:-dev}}"

if [[ -z "${LAYER}" ]]; then
    log_error "Usage: $0 <layer-name> [environment]"
    log_error "Example: $0 100-network dev"
    exit 1
fi

LAYER_DIR="${LAYERS_DIR}/${LAYER}"

if [[ ! -d "${LAYER_DIR}" ]]; then
    log_error "Layer directory not found: ${LAYER_DIR}"
    exit 1
fi

log_info "Applying layer: ${LAYER} (environment: ${ENVIRONMENT})"

# Initialize
tf_init "${LAYER_DIR}"

# Select workspace
tf_workspace_select "${ENVIRONMENT}"

# Apply
tf_apply "${LAYER_DIR}"

log_success "Apply complete for ${LAYER}"
