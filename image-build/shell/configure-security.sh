#!/bin/bash
# Configure Security Hardening

set -euo pipefail

echo "Configuring security hardening..."

# Update SSH configuration
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config

# Enable SSH key-only authentication
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service
sudo systemctl restart ssh

# Install and enable UFW firewall
sudo apt-get install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp  # SSH
sudo ufw allow 8080/tcp  # Application
sudo ufw --force enable

# Configure fail2ban for intrusion prevention
sudo apt-get install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Disable unused services
sudo systemctl disable avahi-daemon || true
sudo systemctl disable cups || true

# Set secure kernel parameters
sudo tee /etc/sysctl.d/99-security.conf > /dev/null <<EOF
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

# Disable swap (if applicable)
vm.swappiness = 10

# Core dump restrictions
kernel.core_uses_pid = 1
fs.suid_dumpable = 0
EOF

sudo sysctl -p /etc/sysctl.d/99-security.conf

echo "Security hardening completed"
