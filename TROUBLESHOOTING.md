# AEOS Container Troubleshooting Guide

This guide helps you diagnose and fix common issues when running AEOS in containers.

## Quick Diagnostics

### 1. Check Container Status

```bash
# Using docker-compose or podman-compose
docker-compose ps
# or
podman-compose ps

# Using docker or podman directly
docker ps -a --filter "name=aeos"
# or
podman ps -a --filter "name=aeos"
```

### 2. View Container Logs

**All containers at once:**
```bash
docker-compose logs -f
# or
podman-compose logs -f
```

**Individual containers:**
```bash
# Database logs
docker-compose logs -f aeos-database
podman-compose logs -f aeos-database

# Lookup server logs
docker-compose logs -f aeos-lookup
podman-compose logs -f aeos-lookup

# Application server logs
docker-compose logs -f aeos-server
podman-compose logs -f aeos-server
```

**Using container runtime directly:**
```bash
docker logs -f aeos-database
docker logs -f aeos-lookup
docker logs -f aeos-server

# Or with podman
podman logs -f aeos-database
podman logs -f aeos-lookup
podman logs -f aeos-server
```

**Get last 100 lines:**
```bash
docker-compose logs --tail=100 aeos-server
```

**Follow logs from specific timestamp:**
```bash
docker-compose logs --since 10m aeos-server
```

### 3. Check Health Status

```bash
# Check health of specific container
docker inspect aeos-database --format '{{.State.Health.Status}}'
docker inspect aeos-lookup --format '{{.State.Health.Status}}'
docker inspect aeos-server --format '{{.State.Health.Status}}'

# Or with podman
podman inspect aeos-database --format '{{.State.Health.Status}}'
podman inspect aeos-lookup --format '{{.State.Health.Status}}'
podman inspect aeos-server --format '{{.State.Health.Status}}'
```

### 4. Execute Commands Inside Containers

```bash
# Get a shell in the container
docker exec -it aeos-server /bin/bash
podman exec -it aeos-server /bin/bash

# Check processes
docker exec aeos-server ps aux
podman exec aeos-server ps aux

# Check network connectivity
docker exec aeos-server nc -zv aeos-database 5432
docker exec aeos-server nc -zv aeos-lookup 2505
```

## Common Issues and Solutions

### Issue 1: Database Container is Unhealthy

**Symptoms:**
- Container status shows "unhealthy"
- Other containers fail to start or connect

**Diagnosis:**
```bash
# Check database logs
docker-compose logs aeos-database

# Check if PostgreSQL is running
docker exec aeos-database ps aux | grep postgres

# Try to connect manually
docker exec -it aeos-database psql -U aeos -d aeos
```

**Solutions:**

1. **Wait longer**: The database may still be initializing
   ```bash
   # Watch the logs
   docker-compose logs -f aeos-database
   ```

2. **Check disk space**:
   ```bash
   df -h
   ```

3. **Remove and recreate the database volume**:
   ```bash
   docker-compose down -v
   docker-compose up -d aeos-database
   ```

4. **Check PostgreSQL logs inside the container**:
   ```bash
   docker exec aeos-database cat /var/lib/postgresql/data/pg_log/postgresql-*.log
   ```

### Issue 2: Lookup Server Container Stays in "Created" State

**Symptoms:**
- Container shows "Created" status but never starts
- Container exits immediately after starting

**Diagnosis:**
```bash
# Check the container logs
docker-compose logs aeos-lookup

# Try to start manually and watch output
docker-compose up aeos-lookup

# Check if the AEOS installation is complete
docker exec aeos-lookup ls -la /opt/aeos/
```

**Solutions:**

1. **Check if database is ready**:
   ```bash
   docker-compose ps aeos-database
   ```
   The lookup server waits for the database to be healthy before starting.

2. **Check entrypoint script**:
   ```bash
   docker exec aeos-lookup cat /usr/local/bin/lookup-entrypoint.sh
   ```

3. **Check if AEOS binaries exist**:
   ```bash
   docker exec aeos-lookup find /opt/aeos -name "*lookup*" -type f
   ```

4. **Manually run the entrypoint**:
   ```bash
   docker exec -it aeos-lookup /bin/bash
   # Inside container:
   /usr/local/bin/lookup-entrypoint.sh start
   ```

### Issue 3: Application Server Container Stays in "Created" State

**Symptoms:**
- Container shows "Created" status but never starts
- Container exits immediately after starting

**Diagnosis:**
```bash
# Check the container logs
docker-compose logs aeos-server

# Try to start manually and watch output
docker-compose up aeos-server

# Check dependencies
docker-compose ps
```

**Solutions:**

1. **Ensure dependencies are running**:
   - Database must be healthy
   - Lookup server must be started
   
   ```bash
   docker-compose ps
   ```

2. **Check entrypoint script**:
   ```bash
   docker exec aeos-server cat /usr/local/bin/entrypoint.sh
   ```

3. **Check if AEOS binaries exist**:
   ```bash
   docker exec aeos-server find /opt/aeos -name "*server*" -type f
   ```

4. **Check configuration files**:
   ```bash
   docker exec aeos-server find /opt/aeos -name "*.properties" -type f
   docker exec aeos-server cat /opt/aeos/config/database.properties
   ```

### Issue 4: Network Connectivity Issues

**Symptoms:**
- Services can't communicate with each other
- Connection timeouts

**Diagnosis:**
```bash
# Check network
docker network ls | grep aeos
podman network ls | grep aeos

# Check if containers are on the same network
docker network inspect aeos-copilot-make-program-a-container_aeos-network

# Test connectivity between containers
docker exec aeos-server ping -c 3 aeos-database
docker exec aeos-server nc -zv aeos-database 5432
docker exec aeos-server nc -zv aeos-lookup 2505
```

**Solutions:**

1. **Recreate the network**:
   ```bash
   docker-compose down
   docker network prune
   docker-compose up -d
   ```

2. **Check firewall rules**:
   ```bash
   # For Podman with firewalld
   sudo firewall-cmd --list-all
   ```

### Issue 5: Port Conflicts

**Symptoms:**
- Error: "port is already allocated"
- Containers fail to bind to ports

**Diagnosis:**
```bash
# Check what's using the ports
sudo lsof -i :5432
sudo lsof -i :2505
sudo lsof -i :2506
sudo lsof -i :8080
sudo lsof -i :8443

# Or with ss
ss -tulpn | grep -E '(5432|2505|2506|8080|8443)'
```

**Solutions:**

1. **Stop conflicting services**:
   ```bash
   # If PostgreSQL is running on host
   sudo systemctl stop postgresql
   ```

2. **Change ports in docker-compose.yml**:
   ```yaml
   ports:
     - "5433:5432"  # Use different host port
   ```

### Issue 6: Permission Issues (Podman specific)

**Symptoms:**
- Permission denied errors
- Unable to create directories or files

**Diagnosis:**
```bash
# Check SELinux context
ls -Z /path/to/volume

# Check user namespace mapping
podman unshare cat /proc/self/uid_map
```

**Solutions:**

1. **Fix SELinux labels**:
   ```bash
   # Add :Z flag to volumes in docker-compose.yml
   volumes:
     - aeos-db-data:/var/lib/postgresql/data:Z
   ```

2. **Run in root mode** (if rootless is causing issues):
   ```bash
   sudo podman-compose up -d
   ```

## Advanced Debugging

### Access Container Filesystem

```bash
# Get a shell in running container
docker exec -it aeos-server /bin/bash

# Copy files from container to host
docker cp aeos-server:/opt/aeos/logs/server.log ./server.log

# Copy files from host to container
docker cp ./config.properties aeos-server:/opt/aeos/config/
```

### Inspect Container Configuration

```bash
# View full container configuration
docker inspect aeos-server

# View environment variables
docker inspect aeos-server --format '{{.Config.Env}}'

# View mounts
docker inspect aeos-server --format '{{.Mounts}}'
```

### Resource Usage

```bash
# Monitor resource usage
docker stats

# Check specific container
docker stats aeos-server
```

### Network Debugging

```bash
# Install network tools in container
docker exec -it aeos-server /bin/bash
apt-get update && apt-get install -y iproute2 iputils-ping dnsutils

# Check DNS resolution
docker exec aeos-server nslookup aeos-database

# Trace network path
docker exec aeos-server traceroute aeos-database
```

## Log Locations

### Container Logs (Runtime logs)
- Docker: `/var/lib/docker/containers/<container-id>/<container-id>-json.log`
- Podman: `~/.local/share/containers/storage/overlay-containers/<container-id>/userdata/`

### Application Logs (Inside containers)
- AEOS Server: `/opt/aeos/logs/`
- AEOS Lookup: `/opt/aeos/logs/`
- PostgreSQL: `/var/lib/postgresql/data/pg_log/`

### Accessing Application Logs
```bash
# List logs
docker exec aeos-server ls -la /opt/aeos/logs/

# View log file
docker exec aeos-server cat /opt/aeos/logs/server.log

# Tail log file
docker exec aeos-server tail -f /opt/aeos/logs/server.log

# Copy log file to host
docker cp aeos-server:/opt/aeos/logs/server.log ./
```

## Cleaning Up

### Stop containers
```bash
docker-compose down
```

### Remove everything including volumes
```bash
docker-compose down -v
```

### Remove orphaned volumes
```bash
docker volume prune
podman volume prune
```

### Remove all AEOS containers and images
```bash
docker-compose down -v --rmi all
# or
podman-compose down -v --rmi all
```

## Getting Help

If you're still experiencing issues:

1. **Collect diagnostic information**:
   ```bash
   # Save all logs
   docker-compose logs > aeos-logs.txt
   
   # Save container status
   docker-compose ps > aeos-status.txt
   
   # Save system info
   docker version > system-info.txt
   docker info >> system-info.txt
   ```

2. **Check the AEOS documentation**: `/home/runner/work/AEOS/AEOS/aeos_technical_help_en_compressed.pdf`

3. **File an issue** on GitHub with:
   - Container status output
   - Relevant log excerpts
   - Steps to reproduce
   - System information (OS, Docker/Podman version)

## Useful Commands Reference

```bash
# Start everything
./start.sh

# Stop everything
docker-compose down

# Restart a specific service
docker-compose restart aeos-server

# View real-time logs
docker-compose logs -f

# Rebuild containers
docker-compose build --no-cache
docker-compose up -d

# Shell into container
docker exec -it aeos-server /bin/bash

# Check health
docker-compose ps
docker inspect <container> --format '{{.State.Health.Status}}'

# Clean restart
docker-compose down -v
docker-compose up -d
```
