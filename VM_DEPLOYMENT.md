# VM Deployment Guide

This guide explains how to deploy AEOS containers on a Virtual Machine (VM), which is the use case mentioned in the original requirement.

## The Problem Statement

> "for me to go to the vm copy the repository and launch the container"

This guide addresses exactly this scenario - copying the repository to a VM and launching the containers.

## Overview

With the new build process, you can:
1. Copy the repository to your VM
2. Run a single command to build and deploy
3. Everything is automatically downloaded and configured

## Prerequisites on VM

Your VM needs:
- Linux OS (Ubuntu 20.04+, Debian 11+, RHEL 8+, etc.)
- Docker or Podman installed
- 8GB RAM minimum (12GB recommended)
- 50GB disk space
- Internet connection (to download the 1.4GB AEOS installer)

## Installation Steps

### Option 1: Quick Deployment (Recommended)

```bash
# 1. Copy repository to VM (via git, scp, or any method)
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS

# 2. Create environment file
cp .env.example .env
nano .env  # Edit passwords

# 3. Deploy everything with one command
./deploy-podman.sh
# OR
docker-compose build && docker-compose up -d
```

That's it! The script will:
- Check prerequisites
- Download the AEOS installer (1.4GB)
- Extract and configure AEOS
- Build container images
- Start all services

### Option 2: Pre-Built Images (Faster)

If you want to avoid building on the VM:

#### On Your Local Machine:
```bash
# 1. Clone and build locally
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS

# 2. Build images
docker-compose build

# 3. Save images to tar files
docker save aeos-server:latest | gzip > aeos-server.tar.gz
docker save aeos-lookup:latest | gzip > aeos-lookup.tar.gz

# 4. Copy tar files to VM
scp aeos-server.tar.gz aeos-lookup.tar.gz user@vm-host:/home/user/
scp -r AEOS user@vm-host:/home/user/
```

#### On Your VM:
```bash
# 1. Load images
docker load < aeos-server.tar.gz
docker load < aeos-lookup.tar.gz

# 2. Start containers
cd AEOS
cp .env.example .env
nano .env  # Edit passwords
docker-compose up -d
```

## VM-Specific Configurations

### Network Configuration

If your VM has a static IP (e.g., 192.168.1.100):

1. Edit `.env`:
```bash
# Allow access from external IPs
AEOS_BIND_ADDRESS=0.0.0.0
```

2. Access AEOS from other machines:
```
http://192.168.1.100:8080/aeos
```

### Firewall Configuration

On the VM, open required ports:

```bash
# For Ubuntu/Debian with UFW
sudo ufw allow 8080/tcp   # AEOS HTTP
sudo ufw allow 8443/tcp   # AEOS HTTPS
sudo ufw allow 2505/tcp   # Lookup Server
sudo ufw allow 2506/tcp   # Application Server
sudo ufw allow 5432/tcp   # PostgreSQL (if needed externally)

# For RHEL/CentOS with firewalld
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8443/tcp
sudo firewall-cmd --permanent --add-port=2505/tcp
sudo firewall-cmd --permanent --add-port=2506/tcp
sudo firewall-cmd --reload
```

### Auto-Start on VM Boot

#### Using Docker Compose

Edit docker-compose.yml to add restart policies (already included):
```yaml
services:
  aeos-server:
    restart: unless-stopped
```

#### Using Systemd (for Podman)

```bash
# Generate systemd unit files
cd AEOS
podman generate systemd --new --files --name aeos-server
podman generate systemd --new --files --name aeos-lookup
podman generate systemd --new --files --name aeos-database

# Move to systemd directory
sudo mv container-*.service /etc/systemd/system/

# Enable services
sudo systemctl enable container-aeos-database.service
sudo systemctl enable container-aeos-lookup.service
sudo systemctl enable container-aeos-server.service

# Start services
sudo systemctl start container-aeos-database.service
sudo systemctl start container-aeos-lookup.service
sudo systemctl start container-aeos-server.service
```

## Typical VM Deployment Workflow

### Scenario: Deploy AEOS on Production VM

```bash
# === On your workstation ===
# 1. Prepare repository
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS

# 2. Configure for production
cp .env.example .env
nano .env  # Set production passwords and settings

# 3. Copy to VM
scp -r . user@production-vm:/opt/aeos/

# === On the VM ===
# 4. Connect to VM
ssh user@production-vm

# 5. Deploy
cd /opt/aeos
./deploy-podman.sh
# OR
docker-compose build && docker-compose up -d

# 6. Check status
docker-compose ps
docker-compose logs -f

# 7. Access AEOS
# Open browser to http://vm-ip:8080/aeos
```

## Troubleshooting on VM

### Build Fails Due to Network Issues

```bash
# Check internet connectivity
ping -c 4 github.com

# Try direct download first
wget https://github.com/tiagorebelo97/AEOS/releases/download/version0/aeosinstall_2023.1.8.sh

# If download works, retry build
docker-compose build
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Clean up Docker/Podman
docker system prune -a
# OR
podman system prune -a

# Remove old images
docker rmi $(docker images -f "dangling=true" -q)
```

### Container Won't Start

```bash
# Check logs
docker-compose logs aeos-server

# Check if ports are available
netstat -tuln | grep -E '8080|5432|2505'

# Check SELinux (if on RHEL/CentOS)
sudo setenforce 0  # Temporarily disable to test
```

### Cannot Access from Other Machines

```bash
# Check firewall
sudo ufw status
# OR
sudo firewall-cmd --list-all

# Check container is listening on all interfaces
docker exec aeos-server netstat -tuln | grep 8080

# Test locally first
curl http://localhost:8080
```

## Maintenance on VM

### Backup

```bash
# Backup database
docker exec aeos-database pg_dump -U aeos aeos > /backup/aeos-db-$(date +%Y%m%d).sql

# Backup volumes
docker run --rm -v aeos-db-data:/data -v /backup:/backup alpine \
    tar czf /backup/aeos-volumes-$(date +%Y%m%d).tar.gz /data
```

### Updates

```bash
# Pull latest code
cd /opt/aeos
git pull

# Rebuild containers
docker-compose build
docker-compose up -d
```

### Monitoring

```bash
# Check resource usage
docker stats

# Check logs
docker-compose logs -f --tail=100

# Check disk space
df -h
du -sh /var/lib/docker
# OR
du -sh ~/.local/share/containers  # For Podman
```

## Performance Tuning for VMs

### Increase Container Resources

Edit docker-compose.yml:

```yaml
services:
  aeos-server:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
```

### Use Volume for Better Performance

For better I/O performance, use volumes instead of bind mounts:

```yaml
volumes:
  aeos-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /fast-storage/aeos-data
```

## Security Best Practices for VM Deployment

1. **Use strong passwords** in `.env`
2. **Enable firewall** and only open required ports
3. **Use HTTPS** in production (configure SSL certificates)
4. **Regular backups** of database and volumes
5. **Keep containers updated** with security patches
6. **Restrict SSH access** to the VM
7. **Enable SELinux/AppArmor** if available
8. **Use non-root user** for Podman

## Summary

The new build process makes VM deployment simple:

1. ✅ **Copy repository** to VM (git clone or scp)
2. ✅ **Run one command** (./deploy-podman.sh)
3. ✅ **Everything is automatic** (download, extract, build, deploy)
4. ✅ **Access AEOS** from browser

No manual installation steps needed! The container build automatically downloads and installs the official AEOS binaries from GitHub releases.
