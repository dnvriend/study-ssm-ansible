# study-ssm-ansible - OpenTofu Infrastructure
#
# Makefile for managing OpenTofu infrastructure layers
#
# Usage:
#   make layer-init LAYER=100-network ENV=dev
#   make layer-plan LAYER=100-network ENV=dev
#   make layer-apply LAYER=100-network ENV=dev

.PHONY: help init fmt validate lint security check clean
.PHONY: layer-init layer-plan layer-apply layer-destroy layer-outputs layer-state
.PHONY: plan-all apply-all destroy-all
.PHONY: setup-state

# Default environment
ENV ?= dev

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Show this help
	@echo "study-ssm-ansible - OpenTofu Infrastructure"
	@echo ""
	@echo "Usage:"
	@echo "  make <target> [LAYER=<layer>] [ENV=<environment>]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Layers:"
	@echo "  100-network, 200-iam, 300-compute, 400-data,"
	@echo "  500-application, 600-dns, 700-lambda"
	@echo ""
	@echo "Environments:"
	@echo "  dev, test, prod"

# =============================================================================
# Development Commands
# =============================================================================

fmt: ## Format all OpenTofu files
	@echo "$(BLUE)Formatting OpenTofu files...$(NC)"
	@tofu fmt -recursive layers/
	@tofu fmt -recursive setup/
	@echo "$(GREEN)Format complete$(NC)"

validate: ## Validate all layers (without backend)
	@echo "$(BLUE)Validating all layers...$(NC)"
	@for dir in layers/*/; do \
		echo "Validating $$(basename $$dir)..."; \
		cd "$$dir" && tofu init -backend=false -input=false > /dev/null && tofu validate && cd ../..; \
	done
	@echo "$(GREEN)Validation complete$(NC)"

lint: ## Run tflint on all layers
	@echo "$(BLUE)Linting all layers...$(NC)"
	@for dir in layers/*/; do \
		echo "Linting $$(basename $$dir)..."; \
		cd "$$dir" && tflint && cd ../..; \
	done 2>/dev/null || echo "$(YELLOW)tflint not installed, skipping$(NC)"

security-gitleaks: ## Run gitleaks for secret detection
	@echo "$(BLUE)Running gitleaks...$(NC)"
	@gitleaks detect --source . --verbose 2>/dev/null || echo "$(YELLOW)gitleaks not installed, skipping$(NC)"

security: security-gitleaks ## Run all security checks

check: fmt validate ## Format and validate all layers

# =============================================================================
# Layer Management Commands
# =============================================================================

layer-init: ## Initialize a layer (LAYER=name ENV=env)
ifndef LAYER
	$(error LAYER is required. Usage: make layer-init LAYER=100-network ENV=dev)
endif
	@echo "$(BLUE)Initializing layer: $(LAYER) ($(ENV))$(NC)"
	@./pipeline/plan-layer.sh $(LAYER) $(ENV) | head -20

layer-plan: ## Plan a layer (LAYER=name ENV=env)
ifndef LAYER
	$(error LAYER is required. Usage: make layer-plan LAYER=100-network ENV=dev)
endif
	@echo "$(BLUE)Planning layer: $(LAYER) ($(ENV))$(NC)"
	@./pipeline/plan-layer.sh $(LAYER) $(ENV)

layer-apply: ## Apply a layer (LAYER=name ENV=env)
ifndef LAYER
	$(error LAYER is required. Usage: make layer-apply LAYER=100-network ENV=dev)
endif
	@echo "$(BLUE)Applying layer: $(LAYER) ($(ENV))$(NC)"
	@./pipeline/apply-layer.sh $(LAYER) $(ENV)

layer-destroy: ## Destroy a layer (LAYER=name ENV=env)
ifndef LAYER
	$(error LAYER is required. Usage: make layer-destroy LAYER=100-network ENV=dev)
endif
	@echo "$(YELLOW)Destroying layer: $(LAYER) ($(ENV))$(NC)"
	@./pipeline/destroy-layer.sh $(LAYER) $(ENV)

layer-outputs: ## Show outputs for a layer (LAYER=name ENV=env)
ifndef LAYER
	$(error LAYER is required. Usage: make layer-outputs LAYER=100-network ENV=dev)
endif
	@./pipeline/outputs.sh $(LAYER) $(ENV)

layer-state: ## Show state for a layer (LAYER=name ENV=env)
ifndef LAYER
	$(error LAYER is required. Usage: make layer-state LAYER=100-network ENV=dev)
endif
	@./pipeline/show-state.sh $(LAYER) $(ENV)

# =============================================================================
# Batch Operations
# =============================================================================

plan-all: ## Plan all layers (ENV=env)
	@echo "$(BLUE)Planning all layers for $(ENV)$(NC)"
	@./pipeline/plan-all.sh $(ENV)

apply-all: ## Apply all layers (ENV=env)
	@echo "$(BLUE)Applying all layers for $(ENV)$(NC)"
	@./pipeline/apply-all.sh $(ENV)

destroy-all: ## Destroy all layers (ENV=env)
	@echo "$(YELLOW)Destroying all layers for $(ENV)$(NC)"
	@./pipeline/destroy-all.sh $(ENV)

# =============================================================================
# State Backend Setup
# =============================================================================

setup-state: ## Bootstrap S3 state backend
	@echo "$(BLUE)Setting up S3 state backend...$(NC)"
	@cd setup && tofu init && tofu apply
	@echo "$(GREEN)State backend ready$(NC)"

# =============================================================================
# Utility Commands
# =============================================================================

clean: ## Clean up temporary files
	@echo "$(BLUE)Cleaning up...$(NC)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.tfplan" -delete 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@rm -rf plans/ 2>/dev/null || true
	@rm -f layers/**/sample_lambda.zip 2>/dev/null || true
	@echo "$(GREEN)Clean complete$(NC)"

list-layers: ## List available layers
	@echo "Available layers:"
	@ls -1 layers/ | grep -E '^[0-9]+'

list-envs: ## List available environments
	@echo "Available environments:"
	@ls layers/100-network/envs/ | sed 's/.tfvars//'
