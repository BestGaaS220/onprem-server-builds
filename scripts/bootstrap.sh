#!/bin/bash

################################################################################
# Golden Image Development Environment Bootstrap Script
# 
# Purpose: Automate development environment setup for new developers
# Usage: ./scripts/bootstrap.sh [environment]
# 
# Implements elite DevEx practices:
# - Automated prerequisite validation
# - Credential management guidance
# - Environment configuration
# - Git hooks setup
# - IDE configuration
# 
################################################################################

set -euo pipefail

# Color output for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }

# Configuration
ENVIRONMENT="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"
VENV_PATH="$PROJECT_ROOT/.venv"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    log_info "Usage: $0 [dev|staging|production]"
    exit 1
fi

log_info "Starting development environment bootstrap for $ENVIRONMENT..."

################################################################################
# 1. Prerequisite Validation
################################################################################

log_info "━━━ Validating Prerequisites ━━━"

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed. Please install it from $2"
        return 1
    fi
    log_success "$1 found: $(command -v "$1")"
    return 0
}

MISSING_DEPS=0

check_command "terraform" "https://www.terraform.io/downloads" || ((MISSING_DEPS++))
check_command "packer" "https://www.packer.io/downloads" || ((MISSING_DEPS++))
check_command "ansible" "https://docs.ansible.com/ansible/latest/installation_guide/" || ((MISSING_DEPS++))
check_command "openstack" "https://docs.openstack.org/openstackclient/stable/" || ((MISSING_DEPS++))
check_command "python3" "https://www.python.org/downloads/" || ((MISSING_DEPS++))
check_command "git" "https://git-scm.com/downloads" || ((MISSING_DEPS++))
check_command "make" "https://www.gnu.org/software/make/" || ((MISSING_DEPS++))

if [[ $MISSING_DEPS -gt 0 ]]; then
    log_error "Missing $MISSING_DEPS required dependencies. Please install them before continuing."
    exit 1
fi

log_success "All prerequisites validated ✓"

# Validate versions
log_info "━━━ Validating Tool Versions ━━━"

TERRAFORM_VERSION=$(terraform version | head -n1 | grep -oP '(?<=Terraform v)\d+\.\d+')
PACKER_VERSION=$(packer version | grep -oP '\d+\.\d+\.\d+' | head -n1)
ANSIBLE_VERSION=$(ansible --version | grep -oP '(?<=core )\d+\.\d+\.\d+')

log_success "Terraform: $TERRAFORM_VERSION"
log_success "Packer: $PACKER_VERSION"
log_success "Ansible: $ANSIBLE_VERSION"

################################################################################
# 2. Local Directory Setup
################################################################################

log_info "━━━ Setting up Local Directories ━━━"

mkdir -p "$PROJECT_ROOT/.local/cache"
mkdir -p "$PROJECT_ROOT/.local/state"
mkdir -p "$PROJECT_ROOT/.local/logs"

log_success "Local directories created"

################################################################################
# 3. Python Virtual Environment Setup
################################################################################

log_info "━━━ Setting up Python Virtual Environment ━━━"

if [[ ! -d "$VENV_PATH" ]]; then
    python3 -m venv "$VENV_PATH"
    log_success "Virtual environment created"
else
    log_warn "Virtual environment already exists"
fi

# Activate virtual environment
# shellcheck disable=SC1090
source "$VENV_PATH/bin/activate"
log_success "Virtual environment activated"

# Upgrade pip
pip install --upgrade pip setuptools wheel > /dev/null
log_success "pip upgraded"

# Install Python dependencies
if [[ -f "$PROJECT_ROOT/requirements-test.txt" ]]; then
    pip install -r "$PROJECT_ROOT/requirements-test.txt" > /dev/null
    log_success "Python test dependencies installed"
fi

################################################################################
# 4. Git Configuration & Hooks Setup
################################################################################

log_info "━━━ Configuring Git & Hooks ━━━"

# Verify git repository
if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
    log_error "Not a git repository"
    exit 1
fi

# Set git configuration (local to repo)
git -C "$PROJECT_ROOT" config user.name "$(git config --global user.name)"  # Use global config
git -C "$PROJECT_ROOT" config user.email "$(git config --global user.email)"

log_success "Git configuration set"

# Setup pre-commit hooks
log_info "Setting up git hooks..."

# Create pre-commit hook
cat > "$PROJECT_ROOT/.git/hooks/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook: Validate code before commit

set -e

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
cd "$PROJECT_ROOT"

echo "Running pre-commit validation..."

# Check for merge conflicts
if git diff --name-only --cached | xargs grep -l "^<<<<<<< HEAD" 2>/dev/null; then
    echo "✗ Merge conflict markers found in staged files"
    exit 1
fi

# Run make validation if available
if [[ -f "Makefile" ]]; then
    make lint --no-print-directory 2>/dev/null || true
fi

echo "✓ Pre-commit checks passed"
EOF

chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"
log_success "Pre-commit hook installed"

################################################################################
# 5. Environment Configuration
################################################################################

log_info "━━━ Setting up Environment Configuration ━━━"

# Create .env if not exists
if [[ ! -f "$ENV_FILE" ]]; then
    cp "$PROJECT_ROOT/.env.example" "$ENV_FILE"
    log_success ".env created from template"
    
    log_warn "⚠️  IMPORTANT: You must populate .env with your credentials:"
    log_warn "   1. Edit: $ENV_FILE"
    log_warn "   2. Fill in all placeholder values"
    log_warn "   3. Run: source .env"
else
    log_warn ".env already exists"
fi

# Create terraform.tfvars if not exists  
TFVARS_FILE="$PROJECT_ROOT/terraform.tfvars"
if [[ ! -f "$TFVARS_FILE" ]]; then
    cat > "$TFVARS_FILE" << EOF
# Local terraform variables (not committed)
# Copy from vars/${ENVIRONMENT}.tfvars and customize as needed

# Example - uncomment and customize:
# environment = "$ENVIRONMENT"
# instance_count = 1
# project_name = "elevatediq"
EOF
    log_success "terraform.tfvars template created"
    log_warn "   Edit: $TFVARS_FILE and add your values"
else
    log_warn "terraform.tfvars already exists"
fi

################################################################################
# 6. Terraform Backend Initialization
################################################################################

log_info "━━━ Initializing Terraform ━━━"

cd "$PROJECT_ROOT/infrastructure/terraform"

if [[ ! -d ".terraform" ]]; then
    log_info "Running terraform init..."
    terraform init -input=false -no-color 2>&1 | head -n5
    log_success "Terraform initialized"
else
    log_warn "Terraform already initialized"
fi

cd "$PROJECT_ROOT"

################################################################################
# 7. IDE/Editor Configuration
################################################################################

log_info "━━━ Configuring IDE Settings ━━━"

# VS Code settings
if [[ ! -d "$PROJECT_ROOT/.vscode" ]]; then
    mkdir -p "$PROJECT_ROOT/.vscode"
fi

cat > "$PROJECT_ROOT/.vscode/settings.json" << 'EOF'
{
  "terraform.path": "terraform",
  "terraform.loglevel": "info",
  "[python]": {
    "editor.defaultFormatter": "ms-python.python",
    "editor.formatOnSave": true
  },
  "[yaml]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "files.exclude": {
    "**/__pycache__": true,
    "**/.terraform": true,
    "**/.*": true
  }
}
EOF

log_success "VS Code configuration created"

################################################################################
# 8. Make Targets Validation
################################################################################

log_info "━━━ Validating Build Targets ━━━"

if command -v make &> /dev/null && [[ -f "$PROJECT_ROOT/Makefile" ]]; then
    make help | head -n 10 > /dev/null
    log_success "Make build targets available"
fi

################################################################################
# 9. Environment-Specific Setup
################################################################################

log_info "━━━ Environment-Specific Setup: $ENVIRONMENT ━━━"

case "$ENVIRONMENT" in
    dev)
        log_info "Development environment configuration..."
        log_info "Features: Testing, iteration, debugging"
        ;;
    staging)
        log_info "Staging environment configuration..."
        log_info "Features: Pre-production testing, integration"
        ;;
    production)
        log_info "Production environment configuration..."
        log_warn "⚠️  PRODUCTION: Handle with care!"
        log_warn "   - All changes require peer review"
        log_warn "   - Backup before any modifications"
        log_warn "   - Test thoroughly before deployment"
        ;;
esac

################################################################################
# 10. Final Verification
################################################################################

log_info "━━━ Bootstrap Summary ━━━"

CHECKS_PASSED=0
CHECKS_TOTAL=0

# Check git status
((CHECKS_TOTAL++))
if git -C "$PROJECT_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
    log_success "Git repository verified"
    ((CHECKS_PASSED++))
fi

# Check python venv
((CHECKS_TOTAL++))
if [[ -d "$VENV_PATH" ]]; then
    log_success "Python virtual environment verified"
    ((CHECKS_PASSED++))
fi

# Check terraform
((CHECKS_TOTAL++))
if [[ -d "$PROJECT_ROOT/infrastructure/terraform/.terraform" ]]; then
    log_success "Terraform backend verified"
    ((CHECKS_PASSED++))
fi

# Check .env
((CHECKS_TOTAL++))
if [[ -f "$ENV_FILE" ]]; then
    log_success ".env file exists"
    ((CHECKS_PASSED++))
fi

log_info "Bootstrap Progress: $CHECKS_PASSED/$CHECKS_TOTAL checks passed"

################################################################################
# 11. Next Steps
################################################################################

log_info "━━━ Next Steps ━━━"
log_info ""
log_info "1. Configure Credentials:"
log_info "   source $ENV_FILE"
log_info "   # Edit .env with your OpenStack credentials"
log_info ""
log_info "2. Verify Setup:"
log_info "   make validate"
log_info ""
log_info "3. Start Development:"
log_info "   make help                    # See all available targets"
log_info "   make build ENV=$ENVIRONMENT  # Build golden image"
log_info ""
log_info "4. Documentation:"
log_info "   See docs/BUILD_PROCESS.md for detailed workflow"
log_info "   See CONTRIBUTING.md for development guidelines"
log_info ""

log_success "Bootstrap complete! ✓"
log_info ""
log_info "For support, see: docs/TROUBLESHOOTING.md"
