#!/bin/bash
################################################################################
# Configure Security Hardening
#
# Purpose: Apply security hardening across the system
# Usage: ./configure-security.sh
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

log_info "Starting security hardening configuration..."

# Ensure root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

################################################################################
# SSH Hardening
################################################################################

log_info "Hardening SSH configuration..."

# Ensure SSH config exists
[[ -f /etc/ssh/sshd_config ]] || {
    log_error "SSH config not found"
    exit 1
}

# Backup original config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%s)

# SSH Configuration Changes
cat >> /etc/ssh/sshd_config << 'SSHEOF'

# Packer Security Hardening
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
X11UseLocalhost yes
AllowTcpForwarding no
AllowAgentForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 5
HostbasedAuthentication no
UsePAM yes
LogLevel VERBOSE
SyslogFacility AUTH
Ciphers chacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256
Compression delayed
TCPKeepAlive yes
PermitUserEnvironment no
PixelPerRow 8
"SSHEOF

# Validate SSH config
sshd -t || {
    log_error "SSH configuration validation failed"
    cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
    exit 1
}

# Restart SSH (but don't stop existing connections)
systemctl restart ssh || true
log_success "SSH hardening completed"

################################################################################
# Firewall Configuration (UFW)
################################################################################

log_info "Configuring firewall..."

apt-get install -y -qq ufw

# Reset ufw to defaults
echo "y" | ufw reset > /dev/null 2>&1 || true

# Configure default policies
ufw default deny incoming
ufw default allow outgoing
ufw default deny routed

# Allow SSH (critical - don't lock ourselves out)
ufw allow 22/tcp comment "SSH"

# Allow application ports
ufw allow 80/tcp comment "HTTP"
ufw allow 443/tcp comment "HTTPS"

# Enable firewall
echo "y" | ufw enable > /dev/null 2>&1

log_success "Firewall configured: $(ufw status | head -1)"

################################################################################
# Intrusion Prevention (fail2ban)
################################################################################

log_info "Installing intrusion prevention..."

apt-get install -y -qq fail2ban

# Create fail2ban local configuration
cat > /etc/fail2ban/jail.local << 'FAIL2BANEOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 1800
FAIL2BANEOF

systemctl enable fail2ban
systemctl restart fail2ban
log_success "Intrusion prevention enabled"

################################################################################
# Kernel Hardening
################################################################################

log_info "Hardening kernel parameters..."

cat > /etc/sysctl.d/99-security.conf << 'SYCTLEOF'
# Kernel protection
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.printk = 3 3 3 3
kernel.unprivileged_ns_clone = 0
kernel.yama.ptrace_scope = 2
kernel.kernel.unprivileged_userns_clone = 0
kernel.core_uses_pid = 1
fs.suid_dumpable = 0

# Restrict access to kernel logs
kernel.sysrq = 0

# Restrict module loading
kernel.modules_disabled = 1

# Network security
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# IPv6 security
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Memory protections
vm.mmap_min_addr = 65536
vm.swappiness = 10

# File system
fs.file-max = 2097152
fs.protected_symlinks = 1
fs.protected_hardlinks = 1
fs.protected_regular = 2
SYCTLEOF

sysctl -p /etc/sysctl.d/99-security.conf > /dev/null 2>&1
log_success "Kernel parameters hardened"

################################################################################
# Disable Unnecessary Services
################################################################################

log_info "Disabling unnecessary services..."

SERVICES_TO_DISABLE=(
    "avahi-daemon"
    "cups"
    "iscsid"
    "rsync"
    "nis"
)

for service in "${SERVICES_TO_DISABLE[@]}"; do
    systemctl disable "$service" > /dev/null 2>&1 || true
    systemctl stop "$service" > /dev/null 2>&1 || true
done

log_success "Unnecessary services disabled"

################################################################################
# File Permissions Hardening
################################################################################

log_info "Hardening file permissions..."

# Set restrictive permissions on sensitive files
chmod 000 /etc/shadow+ || true
chmod 644 /etc/passwd
chmod 644 /etc/group
chmod 600 /etc/ssh/sshd_config
chmod 644 /etc/hosts.allow
chmod 644 /etc/hosts.deny

log_success "File permissions hardened"

################################################################################
# Security Audit Logging
################################################################################

log_info "Configuring audit logging..."

apt-get install -y -qq auditd || true

# Start audit daemon
systemctl enable auditd > /dev/null 2>&1 || true
systemctl restart auditd > /dev/null 2>&1 || true

log_success "Audit logging configured"

################################################################################
# Completion
################################################################################

log_success "Security hardening completed successfully"
log_info "Configuration logged to $LOG_FILE"
log_info "Review: ufw status, systemctl status fail2ban, systemctl status auditd"
