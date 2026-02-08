#!/bin/bash
# Terraform Secrets Management Configuration
# Integrates with GitHub Secrets and cloud provider secret managers

set -euo pipefail

# Source configuration
SECRETS_CONFIG="${SECRETS_CONFIG:-.env.secrets}"
GITHUB_SECRETS_PREFIX="GOLDEN_IMAGE"

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Load secrets from GitHub Actions environment
load_github_secrets() {
  log "Loading GitHub Actions secrets..."
  
  # These are injected by GitHub Actions as environment variables
  export TF_VAR_database_password="${GOLDEN_IMAGE_DB_PASSWORD:-}"
  export TF_VAR_api_key="${GOLDEN_IMAGE_API_KEY:-}"
  export TF_VAR_oauth_client_secret="${GOLDEN_IMAGE_OAUTH_SECRET:-}"
}

# Validate secrets are not empty
validate_secrets() {
  log "Validating required secrets..."
  
  local required_secrets=(
    "TF_VAR_database_password"
    "TF_VAR_api_key"
  )
  
  for secret in "${required_secrets[@]}"; do
    if [[ -z "${!secret:-}" ]]; then
      echo "❌ Missing required secret: $secret"
      return 1
    fi
  done
  
  log "✅ All required secrets present"
}

# Load environment-specific secrets
load_environment_secrets() {
  local env=$1
  log "Loading $env environment secrets..."
  
  case "$env" in
    dev)
      export TF_VAR_environment="dev"
      export TF_VAR_enable_debug="true"
      ;;
    staging)
      export TF_VAR_environment="staging"
      export TF_VAR_enable_debug="false"
      ;;
    prod)
      export TF_VAR_environment="production"
      export TF_VAR_enable_debug="false"
      ;;
    *)
      echo "Unknown environment: $env"
      return 1
      ;;
  esac
}

# Main
main() {
  load_github_secrets
  validate_secrets
  
  if [[ $# -gt 0 ]]; then
    load_environment_secrets "$1"
  fi
  
  log "✅ Secrets management initialized"
}

main "$@"
