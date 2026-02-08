#!/bin/bash
# System Diagnostics Script
# Gathers system and infrastructure information for troubleshooting

set -euo pipefail

readonly OUTPUT_FILE="${1:-diagnostics-$(date +%Y%m%d-%H%M%S).txt}"

{
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              System and Infrastructure Diagnostics              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Timestamp: $(date)"
    echo ""
    
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    uname -a
    echo ""
    
    echo "=== OS Information ==="
    cat /etc/os-release 2>/dev/null || lsb_release -a 2>/dev/null || echo "OS info not available"
    echo ""
    
    echo "=== CPU Information ==="
    nproc 2>/dev/null || echo "CPUs: unknown"
    lscpu 2>/dev/null | head -20 || echo "CPU details not available"
    echo ""
    
    echo "=== Memory Information ==="
    free -h
    echo ""
    
    echo "=== Disk Information ==="
    df -h
    echo ""
    du -sh /* 2>/dev/null | sort -h || echo "Disk usage: not available"
    echo ""
    
    echo "=== Network Information ==="
    echo "Network interfaces:"
    ip addr 2>/dev/null || ifconfig 2>/dev/null || echo "Network info not available"
    echo ""
    
    echo "Network routing:"
    ip route 2>/dev/null || netstat -r 2>/dev/null || echo "Routing info not available"
    echo ""
    
    echo "DNS Configuration:"
    cat /etc/resolv.conf 2>/dev/null || echo "DNS config: not available"
    echo ""
    
    echo "=== Service Status ==="
    systemctl status --no-pager 2>/dev/null | head -20 || echo "Service status: not available"
    echo ""
    
    echo "=== Running Services ==="
    systemctl list-units --type=service --running --no-pager 2>/dev/null | head -20 || echo "Service list: not available"
    echo ""
    
    echo "=== Installed Tools ==="
    echo "Terraform: $(terraform --version 2>/dev/null | head -1 || echo 'not installed')"
    echo "Ansible: $(ansible --version 2>/dev/null | head -1 || echo 'not installed')"
    echo "Packer: $(packer --version 2>/dev/null || echo 'not installed')"
    echo "OpenStack CLI: $(openstack --version 2>/dev/null || echo 'not installed')"
    echo "Python: $(python3 --version 2>/dev/null || echo 'not installed')"
    echo ""
    
    echo "=== Environment Variables ==="
    env | grep -E '^(OS_|TF_|ANSIBLE_|HOME|PATH|PWD)' | sort || echo "No matching environment variables"
    echo ""
    
    echo "=== Disk I/O Performance ==="
    echo "I/O Stats (if available):"
    iostat -h 1 1 2>/dev/null || echo "I/O stats: not available"
    echo ""
    
    echo "=== Logs (Last 20 lines) ==="
    echo "Syslog:"
    tail -20 /var/log/syslog 2>/dev/null || echo "Syslog: not available"
    echo ""
    
    echo "Auth log:"
    tail -20 /var/log/auth.log 2>/dev/null || tail -20 /var/log/secure 2>/dev/null || echo "Auth log: not available"
    echo ""
    
    echo "=== End of Diagnostics ==="
    
} | tee "${OUTPUT_FILE}"

echo ""
echo "Diagnostics saved to: ${OUTPUT_FILE}"
