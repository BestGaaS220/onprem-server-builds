#!/bin/bash
# Validate Golden Image

set -euo pipefail

echo "Validating golden image..."

# Check critical services
echo "Checking services..."
test -f /etc/passwd || (echo "FAIL: /etc/passwd missing" && exit 1)
test -f /etc/shadow || (echo "FAIL: /etc/shadow missing" && exit 1)

# Check network
echo "Checking network..."
ip addr show || (echo "FAIL: Network not configured" && exit 1)

# Check SSH
echo "Checking SSH..."
sshd -t || (echo "FAIL: SSH configuration invalid" && exit 1)

# Check disk space
echo "Checking disk space..."
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
if (( DISK_USAGE > 80 )); then
    echo "WARNING: Disk usage is ${DISK_USAGE}%"
fi

# Check Python
echo "Checking Python..."
python3 --version || (echo "FAIL: Python not installed" && exit 1)

# Verify essential commands
echo "Checking essential commands..."
commands=(curl wget git jq)
for cmd in "${commands[@]}"; do
    command -v "$cmd" > /dev/null || echo "WARNING: $cmd not found"
done

echo "Golden image validation completed successfully"
