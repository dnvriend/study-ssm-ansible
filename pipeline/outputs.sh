#!/bin/bash
# Show outputs for a layer
# Usage: ./outputs.sh <layer-name> [environment]
# Example: ./outputs.sh 100-network dev

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/util.sh"

LAYER="${1:-}"
ENVIRONMENT="${2:-${ENVIRONMENT:-dev}}"

if [[ -z "${LAYER}" ]]; then
    log_error "Usage: $0 <layer-name> [environment]"
    exit 1
fi

LAYER_DIR="${LAYERS_DIR}/${LAYER}"

if [[ ! -d "${LAYER_DIR}" ]]; then
    log_error "Layer directory not found: ${LAYER_DIR}"
    exit 1
fi

log_info "Showing outputs for layer: ${LAYER} (environment: ${ENVIRONMENT})"

# Initialize
tf_init "${LAYER_DIR}"

# Select workspace
tf_workspace_select "${ENVIRONMENT}"

# Show outputs
cd "${LAYER_DIR}"
tofu output
