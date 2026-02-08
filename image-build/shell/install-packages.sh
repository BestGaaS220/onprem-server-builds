#!/bin/bash
# Install Required Packages

set -euo pipefail

echo "Installing application packages..."

# Install Python runtime
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev

# Install Node.js (if needed)
# curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
# sudo apt-get install -y nodejs

# Install monitoring agents
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    prometheus-node-exporter \
    sysstat

# Install container runtime (if needed)
# sudo apt-get install -y docker.io
# sudo usermod -aG docker ubuntu

echo "Application packages installed successfully"
