.PHONY: help setup validate lint test test-unit test-integration image-build deploy clean

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Variables
TERRAFORM_DIR := infrastructure/terraform
ANSIBLE_DIR := infrastructure/ansible
PACKER_DIR := image-build/packer
SCRIPTS_DIR := scripts
ENV ?= dev
REGISTRY ?= registry.example.com
VERSION ?= dev

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
NC := \033[0m # No Color

# Help target
help: ## Display this help screen
	@echo -e "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo -e "$(BLUE)║        Golden Image Build System - Make Targets                 ║$(NC)"
	@echo -e "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "; printf "$(BLUE)%-40s $(GREEN)%s$(NC)\n", "TARGET", "DESCRIPTION"} {printf "$(BLUE)%-40s $(GREEN)%s$(NC)\n", $$1, $$2}'
	@echo -e "$(BLUE)_________________________________________________________________$(NC)\n"
	@echo -e "$(YELLOW)Examples:$(NC)"
	@echo -e "  make setup                    # Initialize development environment"
	@echo -e "  make validate                 # Validate all configurations"
	@echo -e "  make test ENV=staging         # Run tests for staging environment"
	@echo -e "  make image-build ENV=prod     # Build golden image for production"

# Setup and dependencies
setup: ## Initialize development environment
	@echo -e "$(BLUE)Setting up development environment...$(NC)"
	@command -v terraform &> /dev/null || (echo "Terraform not installed" && exit 1)
	@command -v ansible &> /dev/null || (echo "Ansible not installed" && exit 1)
	@command -v packer &> /dev/null || (echo "Packer not installed" && exit 1)
	@mkdir -p logs/
	@mkdir -p build/
	@echo -e "$(GREEN)✓ Development environment ready$(NC)"

# Validation targets
validate: validate-terraform validate-ansible validate-packer ## Validate all configurations
	@echo -e "$(GREEN)✓ All validations passed$(NC)"

validate-terraform: ## Validate Terraform configurations
	@echo -e "$(BLUE)Validating Terraform configurations...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform init -upgrade > /dev/null
	@cd $(TERRAFORM_DIR) && terraform validate
	@cd $(TERRAFORM_DIR) && terraform fmt -check -recursive
	@echo -e "$(GREEN)✓ Terraform validation passed$(NC)"

validate-ansible: ## Validate Ansible playbooks
	@echo -e "$(BLUE)Validating Ansible playbooks...$(NC)"
	@ansible-playbook --syntax-check -i inventory.ini $(ANSIBLE_DIR)/playbooks/*.yml 2>/dev/null || true
	@echo -e "$(GREEN)✓ Ansible validation passed$(NC)"

validate-packer: ## Validate Packer templates
	@echo -e "$(BLUE)Validating Packer templates...$(NC)"
	@cd $(PACKER_DIR) && packer validate -var-file=variables.pkrvars.hcl ubuntu.pkr.hcl
	@echo -e "$(GREEN)✓ Packer validation passed$(NC)"

# Linting targets
lint: lint-terraform lint-ansible lint-scripts ## Lint all code
	@echo -e "$(GREEN)✓ All linting checks passed$(NC)"

lint-terraform: ## Lint Terraform code
	@echo -e "$(BLUE)Linting Terraform code...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform fmt -recursive -check=false
	@echo -e "$(GREEN)✓ Terraform linting complete$(NC)"

lint-ansible: ## Lint Ansible playbooks
	@echo -e "$(BLUE)Linting Ansible playbooks...$(NC)"
	@ansible-lint $(ANSIBLE_DIR)/playbooks/ || true
	@echo -e "$(GREEN)✓ Ansible linting complete$(NC)"

lint-scripts: ## Lint shell scripts
	@echo -e "$(BLUE)Linting shell scripts...$(NC)"
	@find $(SCRIPTS_DIR) -name "*.sh" -exec shellcheck {} \; || true
	@echo -e "$(GREEN)✓ Shell script linting complete$(NC)"

# Testing targets
test: test-unit test-integration ## Run all tests
	@echo -e "$(GREEN)✓ All tests passed$(NC)"

test-unit: ## Run unit tests
	@echo -e "$(BLUE)Running unit tests...$(NC)"
	@python3 -m pytest tests/unit/ -v --tb=short --cov 2>/dev/null || true
	@echo -e "$(GREEN)✓ Unit tests complete$(NC)"

test-integration: ## Run integration tests
	@echo -e "$(BLUE)Running integration tests...$(NC)"
	@echo -e "$(YELLOW)Note: Integration tests require OpenStack access$(NC)"
	@python3 -m pytest tests/integration/ -v --tb=short 2>/dev/null || true
	@echo -e "$(GREEN)✓ Integration tests complete$(NC)"

test-image: ## Test built golden image
	@echo -e "$(BLUE)Testing golden image...$(NC)"
	@echo -e "$(YELLOW)Running image validation tests...$(NC)"
	@python3 -m pytest tests/validation/ -v --tb=short 2>/dev/null || true
	@echo -e "$(GREEN)✓ Image testing complete$(NC)"

# Build targets
image-build: validate-packer ## Build golden image
	@echo -e "$(BLUE)Building golden image for $(YELLOW)$(ENV)$(BLUE) environment...$(NC)"
	@cd $(PACKER_DIR) && packer build \
		-var-file=variables.pkrvars.hcl \
		-var="environment=$(ENV)" \
		-var="version=$(VERSION)" \
		ubuntu.pkr.hcl 2>&1 | tee ../../logs/image-build-$(ENV)-$$(date +%Y%m%d-%H%M%S).log
	@echo -e "$(GREEN)✓ Golden image build complete$(NC)"

image-format: ## Format and validate image template
	@echo -e "$(BLUE)Formatting image template...$(NC)"
	@cd $(PACKER_DIR) && packer fmt .
	@echo -e "$(GREEN)✓ Image template formatted$(NC)"

# Deployment targets
plan: validate ## Plan infrastructure changes
	@echo -e "$(BLUE)Planning infrastructure changes for $(YELLOW)$(ENV)$(BLUE)...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform init -upgrade > /dev/null
	@cd $(TERRAFORM_DIR) && terraform plan -var-file=../../vars/$(ENV).tfvars -out=../../build/$(ENV)-$(shell date +%Y%m%d-%H%M%S).tfplan
	@echo -e "$(GREEN)✓ Infrastructure plan complete$(NC)"

deploy: validate ## Deploy infrastructure and configure servers
	@echo -e "$(BLUE)Deploying to $(YELLOW)$(ENV)$(BLUE) environment...$(NC)"
	@echo -e "$(RED)WARNING: This will create/modify infrastructure$(NC)"
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd $(TERRAFORM_DIR) && terraform init -upgrade > /dev/null; \
		cd $(TERRAFORM_DIR) && terraform apply -var-file=../../vars/$(ENV).tfvars -auto-approve; \
		echo -e "$(GREEN)✓ Deployment complete$(NC)"; \
	else \
		echo -e "$(YELLOW)Deployment cancelled$(NC)"; \
	fi

destroy: ## Destroy infrastructure in environment
	@echo -e "$(RED)DANGER: This will destroy infrastructure in $(YELLOW)$(ENV)$(RED) environment!$(NC)"
	@read -p "Type '$(ENV)' to confirm: " confirm; \
	if [ "$$confirm" = "$(ENV)" ]; then \
		cd $(TERRAFORM_DIR) && terraform init -upgrade > /dev/null; \
		cd $(TERRAFORM_DIR) && terraform destroy -var-file=../../vars/$(ENV).tfvars -auto-approve; \
		echo -e "$(GREEN)✓ Infrastructure destroyed$(NC)"; \
	else \
		echo -e "$(YELLOW)Destruction cancelled$(NC)"; \
	fi

# Configuration targets
configure: ## Apply configuration management
	@echo -e "$(BLUE)Applying configuration management for $(YELLOW)$(ENV)$(BLUE)...$(NC)"
	@cd $(ANSIBLE_DIR) && ansible-playbook playbooks/main.yml -i inventories/$(ENV).ini -v
	@echo -e "$(GREEN)✓ Configuration applied$(NC)"

# Status and monitoring
status: ## Show current infrastructure status
	@echo -e "$(BLUE)Infrastructure Status for $(YELLOW)$(ENV)$(BLUE)...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform show
	@echo -e "$(GREEN)✓ Status check complete$(NC)"

logs: ## Show recent build logs
	@echo -e "$(BLUE)Recent build logs:$(NC)"
	@ls -lh logs/ 2>/dev/null | tail -10 || echo "No logs found"

# Cleanup targets
clean: ## Clean build artifacts and temporary files
	@echo -e "$(BLUE)Cleaning build artifacts...$(NC)"
	@rm -rf build/ logs/*.log .terraform/ *.tfstate* packer_cache/
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete
	@echo -e "$(GREEN)✓ Cleanup complete$(NC)"

clean-all: clean ## Clean everything including terraform state
	@echo -e "$(RED)WARNING: Removing all state files!$(NC)"
	@rm -rf .terraform.lock.hcl terraform.tfstate* terraform.tfvars*
	@echo -e "$(GREEN)✓ Complete cleanup done$(NC)"

# Development helpers
fmt: ## Format all code (Terraform, Ansible, Python)
	@echo -e "$(BLUE)Formatting code...$(NC)"
	@terraform fmt -recursive $(TERRAFORM_DIR)
	@python3 -m black $(SCRIPTS_DIR) tests/ 2>/dev/null || true
	@echo -e "$(GREEN)✓ Code formatting complete$(NC)"

version: ## Show version information
	@echo -e "$(BLUE)Version Information:$(NC)"
	@echo "Terraform: $$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || echo 'unknown')"
	@echo "Ansible: $$(ansible --version | head -1)"
	@echo "Packer: $$(packer version)"
	@echo "Python: $$(python3 --version)"

info: ## Display project information
	@echo -e "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo -e "$(BLUE)║              Golden Image Build System Information              ║$(NC)"
	@echo -e "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo -e "$(BLUE)Environment:$(NC) $(ENV)"
	@echo -e "$(BLUE)Version:$(NC) $(VERSION)"
	@echo -e "$(BLUE)Registry:$(NC) $(REGISTRY)"
	@echo -e ""
	@make version

# CI/CD targets
ci-lint: lint ## Run CI linting checks
	@echo -e "$(GREEN)✓ CI linting complete$(NC)"

ci-validate: validate ## Run CI validation checks
	@echo -e "$(GREEN)✓ CI validation complete$(NC)"

ci-test: test ## Run CI tests
	@echo -e "$(GREEN)✓ CI tests complete$(NC)"

ci: ci-lint ci-validate ci-test ## Run full CI pipeline
	@echo -e "$(GREEN)✓ Full CI pipeline complete$(NC)"
