#!/bin/bash
# Utility functions for pipeline scripts

set -euo pipefail

# Source variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/vars.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# GitLab CI section formatting
gitlab_section_start() {
    local name="$1"
    local title="${2:-$name}"
    if [[ -n "${CI:-}" ]]; then
        echo -e "\e[0Ksection_start:$(date +%s):${name}[collapsed=true]\r\e[0K${title}"
    else
        echo "=== ${title} ==="
    fi
}

gitlab_section_end() {
    local name="$1"
    if [[ -n "${CI:-}" ]]; then
        echo -e "\e[0Ksection_end:$(date +%s):${name}\r\e[0K"
    fi
}

# Initialize OpenTofu for a layer
tf_init() {
    local layer_dir="$1"
    local use_s3_backend="${2:-false}"

    log_info "Initializing OpenTofu in ${layer_dir}"

    cd "${layer_dir}"

    if [[ "${use_s3_backend}" == "true" ]]; then
        tofu init \
            -backend-config="bucket=${TF_STATE_BUCKET}" \
            -backend-config="key=env:/${ENVIRONMENT}/terraform.$(basename "${layer_dir}").tfstate" \
            -backend-config="region=${AWS_REGION}" \
            -backend-config="dynamodb_table=${TF_LOCK_TABLE}" \
            -backend-config="encrypt=true" \
            -reconfigure
    else
        tofu init -reconfigure
    fi
}

# Select or create workspace
tf_workspace_select() {
    local workspace="$1"

    log_info "Selecting workspace: ${workspace}"

    tofu workspace select "${workspace}" 2>/dev/null || tofu workspace new "${workspace}"
}

# Plan a layer
tf_plan() {
    local layer_dir="$1"
    local plan_file="${2:-}"
    local var_file="${layer_dir}/envs/${ENVIRONMENT}.tfvars"

    log_info "Planning layer: $(basename "${layer_dir}")"

    cd "${layer_dir}"

    local plan_args=()
    if [[ -f "${var_file}" ]]; then
        plan_args+=("-var-file=${var_file}")
    fi

    if [[ -n "${plan_file}" ]]; then
        plan_args+=("-out=${plan_file}")
    fi

    tofu plan "${plan_args[@]}"
}

# Apply a layer
tf_apply() {
    local layer_dir="$1"
    local plan_file="${2:-}"

    log_info "Applying layer: $(basename "${layer_dir}")"

    cd "${layer_dir}"

    if [[ -n "${plan_file}" && -f "${plan_file}" ]]; then
        tofu apply -auto-approve "${plan_file}"
    else
        local var_file="${layer_dir}/envs/${ENVIRONMENT}.tfvars"
        local apply_args=("-auto-approve")
        if [[ -f "${var_file}" ]]; then
            apply_args+=("-var-file=${var_file}")
        fi
        tofu apply "${apply_args[@]}"
    fi
}

# Destroy a layer
tf_destroy() {
    local layer_dir="$1"
    local var_file="${layer_dir}/envs/${ENVIRONMENT}.tfvars"

    log_info "Destroying layer: $(basename "${layer_dir}")"

    cd "${layer_dir}"

    local destroy_args=("-auto-approve")
    if [[ -f "${var_file}" ]]; then
        destroy_args+=("-var-file=${var_file}")
    fi

    tofu destroy "${destroy_args[@]}"
}

# Validate all layers
tf_validate_all() {
    log_info "Validating all layers"

    local failed=0
    for layer in "${LAYER_ORDER[@]}"; do
        local layer_dir="${LAYERS_DIR}/${layer}"
        if [[ -d "${layer_dir}" ]]; then
            gitlab_section_start "validate_${layer}" "Validating ${layer}"
            cd "${layer_dir}"
            if ! tofu validate; then
                log_error "Validation failed for ${layer}"
                failed=1
            fi
            gitlab_section_end "validate_${layer}"
        fi
    done

    return $failed
}

# Format check all layers
tf_fmt_check() {
    log_info "Checking format for all layers"

    cd "${REPO_ROOT}"
    if ! tofu fmt -check -recursive layers/; then
        log_error "Format check failed. Run 'tofu fmt -recursive layers/' to fix."
        return 1
    fi
    log_success "Format check passed"
}

# Get layer dependencies
get_layer_dependencies() {
    local layer="$1"

    case "${layer}" in
        "100-network") echo "" ;;
        "200-iam") echo "" ;;
        "300-compute") echo "100-network 200-iam" ;;
        "400-data") echo "100-network" ;;
        "500-application") echo "100-network 200-iam 300-compute 400-data" ;;
        "600-dns") echo "300-compute" ;;
        "700-lambda") echo "100-network 200-iam" ;;
        *) echo "" ;;
    esac
}
