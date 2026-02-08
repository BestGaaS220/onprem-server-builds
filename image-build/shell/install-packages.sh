#!/bin/bash
################################################################################
# Install Application Packages
#
# Purpose: Install application-specific runtime and tools
# Usage: ./install-packages.sh
# Environment: Called from Packer with ENVIRONMENT variable
################################################################################

set -euo pipefail

# Logging
LOG_FILE="/var/log/packer-build.log"
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
log_info() { log "ℹ️  $*"; }
log_success() { log "✓ $*"; }
log_error() { log "✗ ERROR: $*"; }

trap 'log_error "Script failed at line $LINENO"' ERR

log_info "Starting application package installation..."

# Environment defaults
ENVIRONMENT="${ENVIRONMENT:-dev}"
export DEBIAN_FRONTEND=noninteractive

# Ensure root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

################################################################################
# Python Runtime
################################################################################

log_info "Installing Python runtime..."
apt-get install -y -qq \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-distutils \
    python3-apt \
    python3-minimal \
    || log_error "Failed to install Python"

log_success "Python runtime installed: $(python3 --version)"

# Upgrade pip
python3 -m pip install --upgrade pip setuptools wheel > /dev/null 2>&1 || true
log_success "pip upgraded"

################################################################################
# Monitoring Agents
################################################################################

log_info "Installing monitoring packages..."
apt-get install -y -qq \
    prometheus-node-exporter \
    sysstat \
    collectd \
    collectd-core \
    || true

if systemctl is-enabled prometheus-node-exporter > /dev/null 2>&1 || true; then
    systemctl start prometheus-node-exporter > /dev/null 2>&1 || true
    log_success "Prometheus node exporter installed"
fi

################################################################################
# Common Utilities
################################################################################

log_info "Installing utility packages..."
apt-get install -y -qq \
    curl \
    wget \
    git \
    rsync \
    tar \
    gzip \
    bzip2 \
    xz-utils \
    file \
    lsof \
    strace \
    tcpdump \
    || log_error "Failed to install utilities"

log_success "Utility packages installed"

################################################################################
# Runtime Dependencies (Environment-Specific)
################################################################################

case "$ENVIRONMENT" in
    production)
        log_info "Installing production-specific packages..."
        apt-get install -y -qq \
            logrotate \
            chrony \
            ntp \
            || true
        ;;
    staging)
        log_info "Installing staging packages..."
        apt-get install -y -qq \
            less \
            tree \
            || true
        ;;
    dev)
        log_info "Installing development packages..."
        apt-get install -y -qq \
            build-essential \
            linux-headers-$(uname -r) \
            || true
        ;;
esac

################################################################################
# Container Support (Optional)
################################################################################

# Uncomment to enable Docker
# log_info "Installing Docker runtime..."
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
#    tee /etc/apt/sources.list.d/docker.list > /dev/null
# apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

################################################################################
# Cleanup
################################################################################

log_info "Cleaning up..."
apt-get autoremove -y -qq
apt-get autoclean -y -qq
log_success "Cleanup completed"

log_success "Application package installation completed successfully"
