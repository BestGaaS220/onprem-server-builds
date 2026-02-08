#!/bin/bash
# Update System Packages

set -euo pipefail

echo "Updating system packages..."

# Update package lists
sudo apt-get update

# Upgrade packages
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install essential packages
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    wget \
    git \
    htop \
    net-tools \
    lsof \
    tmux \
    vim \
    jq \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

echo "System packages updated successfully"
