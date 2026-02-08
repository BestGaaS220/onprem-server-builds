#!/bin/bash
# Secret Validation Script - NIST-IA-5 Compliance
# Validates no sensitive information is in the workspace

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔒 Starting Secret Validation..."

# Check for forbidden secret files
FORBIDDEN_PATTERNS=(
  "service-account.json"
  ".env"
  "id_rsa"
  "id_ed25519"
  "id_dsa"
  "*.pem"
  "credentials.json"
  "*.key"
  "*.pfx"
  "*.p12"
)

FOUND_SECRETS=0

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  files=$(find . -name "$pattern" \
    -not -path "./.git/*" \
    -not -path "./node_modules/*" \
    -not -path "./.venv/*" \
    -not -path "./.terraform/*" \
    2>/dev/null || true)
  
  if [[ -n "$files" ]]; then
    echo -e "${RED}❌ FOUND SENSITIVE FILES: $pattern${NC}"
    echo "$files"
    FOUND_SECRETS=1
  fi
done

# Check for hardcoded secrets patterns
echo "Scanning for hardcoded secrets patterns..."
POTENTIAL_SECRETS=$(grep -rnE \
  "password\s*=|secret\s*=|api_key\s*=|token\s*=|access_key\s*=" \
  . \
  --exclude-dir={.git,node_modules,.terraform,.venv,.pyc} \
  --exclude="*.md" \
  --exclude="secret_validator.sh" \
  2>/dev/null || true)

if [[ -n "$POTENTIAL_SECRETS" ]]; then
  echo -e "${YELLOW}⚠️ WARNING: Potential hardcoded secrets detected (review):${NC}"
  echo "$POTENTIAL_SECRETS" | head -20
fi

# Check for AWS/GCP credentials in environment
if [[ -n "${AWS_SECRET_ACCESS_KEY:-}" ]] || [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  echo -e "${RED}❌ Credentials found in environment variables${NC}"
  FOUND_SECRETS=1
fi

if [[ $FOUND_SECRETS -eq 0 ]]; then
  echo -e "${GREEN}✅ Secret validation passed${NC}"
  exit 0
else
  echo -e "${RED}❌ Secret validation FAILED${NC}"
  exit 1
fi
