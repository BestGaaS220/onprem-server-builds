#!/bin/bash
################################################################################
# Validate Golden Image
#
# Purpose: Comprehensive validation of golden image build
# Usage: ./validate-image.sh
# Environment: Runs post-build to ensure image quality
################################################################################

set -euo pipefail

# Logging setup
LOG_FILE="/var/log/packer-validation.log"
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
log_info() { log "ℹ️  $*"; }
log_success() { log "✓ $*"; }
log_warn() { log "⚠️  $*"; }
log_error() { log "✗ ERROR: $*"; }

# Variables
VALIDATION_PASSED=0
VALIDATION_FAILED=0
VALIDATION_WARNINGS=0

# Validation helper
validate() {
    local name="$1"
    local command="$2"
    
    log_info "Checking: $name..."
    if eval "$command" > /dev/null 2>&1; then
        log_success "$name: PASSED"
        ((VALIDATION_PASSED++))
        return 0
    else
        log_error "$name: FAILED"
        ((VALIDATION_FAILED++))
        return 1
    fi
}

# Warning check
warn() {
    local name="$1"
    local command="$2"
    
    log_info "Checking: $name..."
    if eval "$command" > /dev/null 2>&1; then
        log_success "$name: OK"
        return 0
    else
        log_warn "$name: WARNING"
        ((VALIDATION_WARNINGS++))
        return 1
    fi
}

log_info "Starting golden image validation..."

################################################################################
# Critical Validations (Build Cannot Continue)
################################################################################

echo ""
log_info "━━━ Critical System Validations ━━━"

# OS Files
validate "passwd file exists" "[[ -f /etc/passwd ]]"
validate "shadow file exists" "[[ -f /etc/shadow ]]"
validate "hostname configured" "[[ -n \$(hostname 2>/dev/null) ]]"

# SSH
validate "SSH server installed" "command -v ssh > /dev/null"
validate "SSH config valid" "sshd -t"
validate "SSH key-only auth" "grep -q '^PasswordAuthentication no' /etc/ssh/sshd_config"

# Network
validate "network loopback" "ip link show lo"
validate "hostname resolution" "grep -q localhost /etc/hosts"

# Runtime
validate "bash shell" "command -v bash"
validate "python3 runtime" "command -v python3"
validate "curl utility" "command -v curl"
validate "wget utility" "command -v wget"

################################################################################
# Security Validations
################################################################################

echo ""
log_info "━━━ Security Validations ━━━"

validate "root login disabled" "grep -q '^PermitRootLogin no' /etc/ssh/sshd_config"
validate "x11 forwarding disabled" "grep -q '^X11Forwarding no' /etc/ssh/sshd_config"
validate "key-based auth enabled" "grep -q '^PubkeyAuthentication yes' /etc/ssh/sshd_config"
validate "firewall installed" "command -v ufw"
validate "fail2ban installed" "command -v fail2ban-server"
validate "auditd installed" "command -v auditd"

# Kernel parameters
validate "kernel hardening (ptrace scope)" "[[ \$(sysctl -n kernel.yama.ptrace_scope 2>/dev/null) -ge 2 ]]"
validate "kernel hardening (core dumps)" "[[ \$(sysctl -n kernel.core_uses_pid 2>/dev/null) -eq 1 ]]"
validate "network hardening (redirects)" "[[ \$(sysctl -n net.ipv4.conf.all.send_redirects 2>/dev/null) -eq 0 ]]"

################################################################################
# System State Validations
################################################################################

echo ""
log_info "━━━ System State Validations ━━━"

# Disk space (warning level)
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
if [[ $DISK_USAGE -gt 80 ]]; then
    log_warn "High disk usage: ${DISK_USAGE}%"
    ((VALIDATION_WARNINGS++))
else
    log_success "Disk usage acceptable: ${DISK_USAGE}%"
    ((VALIDATION_PASSED++))
fi

# Package updates
validate "apt cache updated" "[[ ! -z \$(apt-cache search --names '\.' | wc -l) ]] | grep -v '^0$'"

# Log files present
validate "system logs exist" "[[ -f /var/log/syslog || -f /var/log/messages ]]"
validate "auth logs exist" "[[ -f /var/log/auth.log || -f /var/log/secure ]]"

################################################################################
# Package Validations
################################################################################

echo ""
log_info "━━━ Package Validations ━━━"

PACKAGES=(
    "build-essential:build tools"
    "curl:HTTP client"
    "wget:file downloader"
    "git:version control"
    "openssl:cryptography"
    "openssh-client:SSH client"
    "openssh-server:SSH server"
)

for package_check in "${PACKAGES[@]}"; do
    IFS=':' read -r pkg desc <<< "$package_check"
    warn "$desc ($pkg)" "dpkg -l | grep -q '^ii.*$pkg '"
done

################################################################################
# Service Validations
################################################################################

echo ""
log_info "━━━ Service Validations ━━━"

# Check critical services can start
validate "SSH service operational" "systemctl is-active ssh > /dev/null 2>&1 || systemctl restart ssh > /dev/null 2>&1"

# Check for disabled unnecessary services
for service in avahi-daemon cups; do
    if systemctl is-enabled "$service" > /dev/null 2>&1; then
        log_warn "Unnecessary service enabled: $service"
        ((VALIDATION_WARNINGS++))
    else
        log_success "Unnecessary service disabled: $service"
        ((VALIDATION_PASSED++))
    fi
done

################################################################################
# File System Validations
################################################################################

echo ""
log_info "━━━ File System Validations ━━━"

validate "no extra SSH host keys" "[[ \$(find /etc/ssh -name 'ssh_host_*' | wc -l) -gt 0 ]]"
validate "temp directories writable" "[[ -w /tmp && -w /var/tmp ]]"
validate "home directory exists" "[[ -d /root ]]"

################################################################################
# Environment Metadata
################################################################################

echo ""
log_info "━━━ Image Metadata ━━━"

log_info "Build Environment Information:"
log "  Hostname: $(hostname)"
log "  Kernel: $(uname -r)"
log "  OS: $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
log "  Packer Version: ${PACKER_VERSION:-unknown}"
log "  Build Environment: ${ENVIRONMENT:-dev}"
log "  Build Date: ${BUILD_DATE:-$(date)}"
log "  Disk Space Used: ${DISK_USAGE}%"
log "  Memory Total: $(free -h | awk 'NR==2 {print $2}')"

################################################################################
# Summary & Exit Status
################################################################################

echo ""
log_info "━━━ Validation Summary ━━━"
log "Passed:  $VALIDATION_PASSED"
log "Warnings: $VALIDATION_WARNINGS"
log "Failed:  $VALIDATION_FAILED"

if [[ $VALIDATION_FAILED -gt 0 ]]; then
    log_error "Validation FAILED - Image has $VALIDATION_FAILED critical issues"
    exit 1
elif [[ $VALIDATION_WARNINGS -gt 0 ]]; then
    log_warn "Validation PASSED with $VALIDATION_WARNINGS warnings"
    exit 0
else
    log_success "Validation PASSED - Image is ready for deployment"
    exit 0
fi
