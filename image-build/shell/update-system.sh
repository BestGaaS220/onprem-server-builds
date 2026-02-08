#!/bin/bash
################################################################################
# Update System Packages
#
# Purpose: Update all system packages and install base utilities
# Usage: ./update-system.sh
# Environment: Runs with sudo privileges (called from Packer)
################################################################################

set -euo pipefail

# Logging
LOG_FILE="/var/log/packer-build.log"
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
log_info() { log "ℹ️  $*"; }
log_success() { log "✓ $*"; }
log_error() { log "✗ ERROR: $*"; }

trap 'log_error "Script failed at line $LINENO"' ERR

log_info "Starting system package update..."

# Ensure we're running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

# Set environment
export DEBIAN_FRONTEND=noninteractive
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Update package lists
log_info "Updating package lists..."
apt-get update -qq || log_error "Failed to update package lists"
log_success "Package lists updated"

# Upgrade packages (non-interactive)
log_info "Upgrading system packages..."
apt-get upgrade -y -qq || log_error "Failed to upgrade packages"
log_success "System packages upgraded"

# Install essential utilities
log_info "Installing essential packages..."
apt-get install -y -qq \
    build-essential \
    curl \
    wget \
    git \
    htop \
    net-tools \
    lsof \
    tmux \
    vim-tiny \
    jq \
    unzip \
    zip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    openssh-client \
    openssh-server \
    openssh-sftp-server \
    iputils-ping \
    dnsutils \
    telnet \
    time \
    tzdata \
    sudo \
    || log_error "Failed to install essential packages"

log_success "Essential packages installed"

# Install security tools
log_info "Installing security tools..."
apt-get install -y -qq \
    openssh-client \
    sudo \
    apt-listchanges \
    needrestart \
    || log_error "Failed to install security tools"

log_success "Security tools installed"

# Enable automatic security updates
log_info "Configuring automatic security updates..."
apt-get install -y -qq unattended-upgrades
if [[ -f /etc/apt/apt.conf.d/50unattended-upgrades ]]; then
    sed -i 's|//Unattended-Upgrade::Mail "root";|Unattended-Upgrade::Mail "root";|' /etc/apt/apt.conf.d/50unattended-upgrades
    log_success "Automatic security updates configured"
fi

# Clean up apt cache
log_info "Cleaning apt cache..."
apt-get autoremove -y -qq
apt-get autoclean -y -qq
apt-get clean -y -qq
log_success "Apt cache cleaned"

# Final verification
log_info "Verifying system updates..."
if ! apt-get upgrade -s | grep -q "upgraded"; then
    log_success "All packages up to date"
fi

log_success "System package update completed successfully"
