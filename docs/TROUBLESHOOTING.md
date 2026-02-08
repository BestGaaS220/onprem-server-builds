# Troubleshooting Guide

## Common Issues and Solutions

### Build Issues

#### Issue: Packer build fails with "image not found"

**Symptoms:**
```
OpenStack builder: Error: ImageNotFound
```

**Solution:**
```bash
# Verify image availability
openstack image list | grep -i ubuntu

# Update Packer variables
vim image-build/packer/variables.pkrvars.hcl
# Set correct source_image

# Retry build
make image-build ENV=dev
```

---

#### Issue: Packer runs out of disk space

**Symptoms:**
```
No space left on device
```

**Solution:**
```bash
# Check disk usage
df -h

# Clean Packer cache
rm -rf packer_cache/
rm -rf /tmp/packer*

# Free up space (remove old images)
openstack image delete old-image-v1.0.0

# Clear temporary files
make clean

# Retry with more disk space
```

---

#### Issue: Ansible provisioner timeout

**Symptoms:**
```
timeout: timed out after 5 minutes waiting for SSH
```

**Solution:**
```bash
# Increase timeout in Packer template
vim image-build/packer/ubuntu.pkr.hcl
# Change: ssh_wait_timeout = "10m"

# Verify OpenStack firewall allows SSH (22)
openstack security group list
openstack security group show <group>

# Check instance logs
openstack console log show <instance-id>

# Rebuild
make image-build ENV=dev
```

---

### Terraform Issues

#### Issue: "Resource already exists" error

**Symptoms:**
```
Error: Instance ... already exists
```

**Solution:**
```bash
# Import existing resource
terraform import \
  openstack_compute_instance_v2.web_server \
  <instance-id>

# Or remove from state and re-create
terraform state rm openstack_compute_instance_v2.web_server
terraform apply
```

---

#### Issue: Terraform state corruption

**Symptoms:**
```
Error: state file corrupted
```

**Solution:**
```bash
# Backup current state
cp terraform.tfstate terraform.tfstate.backup

# Restore from backup
terraform state pull > state.backup
terraform state push state.backup

# Or refresh state
terraform refresh

# Redeploy if necessary
terraform apply -refresh-only
```

---

#### Issue: "No valid host was found"

**Symptoms:**
```
Error: No valid host was found
```

**Solution:**
```bash
# Verify OpenStack credentials
openstack token issue

# Check cloud.yaml configuration
cat ~/.config/openstack/clouds.yaml

# Test OpenStack CLI
openstack server list

# Update terraform vars
vim vars/dev.tfvars
# Verify: os_auth_url, os_region_name, os_project_id

# Retry
terraform init && terraform apply
```

---

### Ansible Issues

#### Issue: "SSH: UNREACHABLE"

**Symptoms:**
```
UNREACHABLE! => {
    "changed": false,
    "msg": "Failed to connect to the host via ssh: ..."
}
```

**Solution:**
```bash
# Verify SSH key permissions
chmod 600 ~/.ssh/deployer-key.pem

# Test SSH manually
ssh -i ~/.ssh/deployer-key.pem ubuntu@<server-ip>

# Check if server is running
openstack server list

# Verify security group allows SSH
openstack security group show default

# Check instance logs
openstack console log show <instance-id>

# Update inventory SSH settings
vim infrastructure/ansible/inventories/dev.ini
# Verify: ansible_ssh_private_key_file, ansible_user
```

---

#### Issue: "Permission denied: /etc/..." (non-root changes)

**Symptoms:**
```
Permission denied: /etc/config.yml
```

**Solution:**
```yaml
# Use become for privileged operations
- name: Copy config file
  copy:
    src: config.yml
    dest: /etc/elevatediq/config.yml
  become: yes  # Run with sudo

# Or use become_user
- name: Create user directory
  file:
    path: /opt/elevatediq
    state: directory
  become: yes
```

---

#### Issue: "apt module not found" on CentOS/RHEL

**Symptoms:**
```
ERROR! couldn't resolve module/action 'apt'
```

**Solution:**
```yaml
# Use package module instead (distribution-agnostic)
- name: Install package
  package:
    name: nginx
    state: present

# Or use appropriate module
- name: Install on Debian
  apt:
    name: nginx
  when: ansible_os_family == "Debian"

- name: Install on RedHat
  yum:
    name: nginx
  when: ansible_os_family == "RedHat"
```

---

### Network Issues

#### Issue: Instances cannot reach external network

**Symptoms:**
```
ping: sendmsg: Network unreachable
```

**Solution:**
```bash
# Verify network configuration
openstack network show <network>
openstack router list
openstack router show <router>

# Check firewall rules
openstack security group show <security-group>

# Verify routes
ip route show

# Enable IP forwarding (if router)
sudo sysctl -w net.ipv4.ip_forward=1

# Test connectivity
ping 8.8.8.8
```

---

#### Issue: DNS resolution fails

**Symptoms:**
```
getaddrinfo: Name or service not known
```

**Solution:**
```bash
# Test DNS resolution
nslookup example.com
dig example.com

# Check DNS configuration
cat /etc/resolv.conf

# Update via cloud-init
vim image-build/cloud-init/network-config

# Manually update
sudo nano /etc/resolv.conf
nameserver 8.8.8.8

# Or via DHCP
sudo dhclient -r
sudo dhclient
```

---

### Service Issues

#### Issue: Service fails to start

**Symptoms:**
```
elevatediq.service: Main process exited, code=exited, status=1
```

**Solution:**
```bash
# Check service status
systemctl status elevatediq

# View service logs
journalctl -u elevatediq -n 100 -f

# Check configuration
cat /etc/elevatediq/config.yml

# Verify file permissions
ls -la /etc/elevatediq/
ls -la /opt/elevatediq/

# Test manual startup
/opt/elevatediq/bin/app --config /etc/elevatediq/config.yml

# Restart service
systemctl restart elevatediq
journalctl -u elevatediq -n 20
```

---

#### Issue: Service port already in use

**Symptoms:**
```
Error: bind: address already in use
Port 8080 is in use by: PID 1234
```

**Solution:**
```bash
# Find process using port
lsof -i :8080
netstat -tulnp | grep 8080

# Kill process (if safe)
kill -9 1234

# Or change port in configuration
vim /etc/elevatediq/config.yml
# Change: port: 8081

# Or check what's running
ps aux | grep elevatediq
systemctl list-units --type=service --running
```

---

### Performance Issues

#### Issue: Slow application response

**Symptoms:**
- Response time > expected
- High CPU utilization
- High memory usage

**Solution:**
```bash
# Check system resources
top -b -n 1 | head -20
free -h
df -h
iostat -x 1 5

# Check application logs for errors
tail -f /var/log/elevatediq/application.log

# Check database performance
# (For PostgreSQL)
psql -U elevatediq -d elevatediq
SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;

# Check network performance
iftop -n

# Optimize query if needed
EXPLAIN ANALYZE <slow-query>;
```

---

#### Issue: High memory usage/OOM errors

**Symptoms:**
```
Out of memory: Kill process
Killed process 1234 (java) total-vm:2000000kB
```

**Solution:**
```bash
# Check memory usage
free -h
ps aux --sort=-%mem | head -10

# Check heap usage (Java apps)
jps -l
jmap -heap <pid>

# Increase memory allocation
# Edit service file
sudo systemctl edit elevatediq
# Add: Environment="JAVA_OPTS=-Xmx4g -Xms2g"

# Or increase system RAM
# Edit Terraform variables:
vim vars/prod.tfvars
instance_flavor = "m1.xlarge"  # Larger instance

terraform plan && terraform apply
```

---

### Security Issues

#### Issue: SSL certificate errors

**Symptoms:**
```
SSL: CERTIFICATE_VERIFY_FAILED
```

**Solution:**
```bash
# Verify certificate validity
openssl x509 -in /etc/ssl/certs/server.crt -text -noout

# Check expiration
openssl x509 -in /etc/ssl/certs/server.crt -noout -dates

# Regenerate self-signed certificate (dev only!)
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/server.key \
  -out /etc/ssl/certs/server.crt

# For production, renew from CA
# Use certbot or manual renewal process
```

---

#### Issue: Failed login attempts

**Symptoms:**
```
Multiple failed SSH attempts
Failed password for invalid user
```

**Solution:**
```bash
# Check failed attempts
sudo grep "Failed password" /var/log/auth.log | wc -l

# Update SSH configuration
sudo nano /etc/ssh/sshd_config
# Enable:
#   PermitRootLogin no
#   PubkeyAuthentication yes
#   PasswordAuthentication no
#   MaxAuthTries 3
#   LoginGraceTime 20

sudo systemctl restart ssh

# Enable fail2ban
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

---

### Database Issues

#### Issue: Database connection refused

**Symptoms:**
```
could not connect to server
FATAL: Ident authentication failed for user "elevatediq"
```

**Solution:**
```bash
# Check if database is running
systemctl status postgresql

# Check connections
sudo -u postgres psql -c "select * from pg_stat_activity;"

# Verify authentication
cat /etc/postgresql/*/main/pg_hba.conf

# Check network connectivity
nc -zv db-server 5432

# Verify credentials in app config
grep -i "database" /etc/elevatediq/config.yml

# Restart database
sudo systemctl restart postgresql
```

---

#### Issue: Database transactions slow/locked

**Symptoms:**
```
statement timeout
deadlock detected
```

**Solution:**
```bash
# Check active connections
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity WHERE state != 'idle';"

# Check locks
sudo -u postgres psql -c "SELECT * FROM pg_locks WHERE NOT granted;"

# Kill long-running query
sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE duration > interval '10 minutes';"

# Optimize query
EXPLAIN ANALYZE <query>;

# Increase work_mem
sudo nano /etc/postgresql/*/main/postgresql.conf
# work_mem = '256MB'
```

---

## General Troubleshooting Steps

### 1. Gather Information

```bash
# System information
uname -a
lsb_release -a
uname -r

# Service status
systemctl status <service>

# Logs
journalctl -u <service> -n 50
tail -f /var/log/<app>/<file>.log

# Network info
ip addr
ip route
netstat -tulnp
```

### 2. Check Resource Constraints

```bash
# CPU
top -n 1 | grep -i cpu
mpstat -P ALL 1 1

# Memory
free -h
vmstat 1 5

# Disk
df -h
du -sh /*

# I/O
iostat -x 1
fio --name=test --ioengine=libaio
```

### 3. Verify Configuration

```bash
# Application config
cat /etc/<app>/config.yml

# Environment variables
env | grep -i app
systemctl show <service>

# File permissions
ls -la /etc/<app>/
ls -la /opt/<app>/
```

### 4. Check Connectivity

```bash
# Network
ping <target>
traceroute <target>
mtr <target>

# Ports
telnet <host> <port>
nc -zv <host> <port>

# DNS
nslookup <domain>
dig <domain>
```

### 5. Common Commands

```bash
# Get detailed logs
journalctl -u <service> --since "2 hours ago" -f

# Check process
ps aux | grep <process>
pgrep -a <process>

# Restart service
sudo systemctl restart <service>
systemctl status <service>

# Debug mode
<command> --debug -vv
```

## Escalation and Support

If issue persists after troubleshooting:

1. **Collect diagnostic information**
   ```bash
   # Run diagnostic script
   ./scripts/diagnose.sh > diagnostics-$(date +%Y%m%d).txt
   ```

2. **Check documentation**
   - [Architecture](../ARCHITECTURE.md)
   - [Build Process](./BUILD_PROCESS.md)
   - [Deployment Guide](./DEPLOYMENT.md)

3. **Review logs**
   - Application logs: `/var/log/elevatediq/`
   - System logs: `/var/log/{syslog,messages}`
   - Ansible logs: `/var/log/ansible.log`
   - Terraform logs: review terminal output

4. **Contact support**
   - Include diagnostic information
   - Include relevant logs (sanitized for secrets)
   - Include steps to reproduce
   - Include environment details

5. **Create GitHub issue**
   - Reference issue template
   - Include diagnostic output
   - Include detailed symptoms
   - Include reproduction steps
