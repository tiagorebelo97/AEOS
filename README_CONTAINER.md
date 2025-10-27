# AEOS Containerized Deployment

## Overview

This repository contains a containerized version of the **AEOS (Access Control and Security Management System)** by Nedap Security Management. The original AEOS system requires Windows Server installation, but this implementation allows you to run AEOS components in containers using Docker or Podman.

### Container Build Process

The containerized AEOS uses the **official AEOS installer** (`aeosinstall_2023.1.8.sh`) from the [GitHub releases](https://github.com/tiagorebelo97/AEOS/releases/tag/version0). During the Docker/Podman build:

1. Downloads the 1.4GB installer from GitHub releases
2. Extracts the complete AEOS installation (WildFly, libraries, tools)
3. Configures it for containerized deployment
4. Creates production-ready container images

This ensures that the containerized version contains the **exact same binaries** as the traditional AEOS installation, just running in containers instead of directly on Windows Server.

### What is AEOS?

AEOS is an enterprise-level physical access control system that manages:
- **Door access control** for buildings and facilities
- **Security badge issuance** and management
- **Access authorization** based on templates and schedules
- **Physical door controllers (AEpus)** that operate door hardware
- **Real-time access events** monitoring and logging
- **Multi-site deployments** with centralized management

### System Architecture

The containerized AEOS system consists of three main components:

1. **AEOS Application Server** (`aeos-server`)
   - Java-based application running on Tomcat
   - Web interface for system administration
   - Badge issuance and carrier management
   - Ports: 8080 (HTTP), 8443 (HTTPS), 2506 (App Server)

2. **AEOS Lookup Server** (`aeos-lookup`)
   - Handles network communication between components
   - Coordinates door controller connections
   - Port: 2505

3. **PostgreSQL Database** (`aeos-database`)
   - Stores all system data (carriers, access points, authorizations, events)
   - Port: 5432

## Prerequisites

- **Docker** (version 20.10+) or **Podman** (version 3.0+)
- **Docker Compose** or **Podman Compose**
- Minimum 8GB RAM (12GB recommended for building)
- 50GB disk space (10GB for build, 20GB for runtime)
- Internet connection (to download 1.4GB AEOS installer during build)

## Quick Start

### Simplest Method (Universal Script)

Just clone and run:

```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
./start.sh
```

The `start.sh` script automatically:
- Detects whether you have Docker or Podman
- Creates a secure `.env` file with random password
- Builds all container images
- Starts all services

**No manual configuration needed!** Access AEOS at http://localhost:8080/aeos

### Using Docker Compose

1. **Clone the repository:**
   ```bash
   git clone https://github.com/tiagorebelo97/AEOS.git
   cd AEOS
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   # Edit .env and set secure passwords
   nano .env
   ```

3. **Build the containers:**
   ```bash
   docker-compose build
   # This downloads and installs AEOS (takes 10-20 minutes)
   ```

4. **Start the containers:**
   ```bash
   docker-compose up -d
   ```

5. **Check container status:**
   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

6. **Access AEOS:**
   - Web Interface: http://localhost:8080/aeos
   - HTTPS: https://localhost:8443/aeos
   - Default credentials: admin/admin (change on first login)

### Using Podman (Simplest Method)

1. **Clone and start with one command:**
   ```bash
   git clone https://github.com/tiagorebelo97/AEOS.git
   cd AEOS
   ./deploy-podman.sh
   ```
   
   That's it! The script automatically:
   - Creates a secure `.env` file with random password
   - Builds all container images
   - Starts all services with proper sequencing
   - Verifies containers are running
   
   **No manual configuration needed!**

2. **Check pod status:**
   ```bash
   # Using the helper script (recommended)
   ./view-logs.sh status
   
   # Or using podman directly
   podman ps -a
   ```

3. **View logs:**
   ```bash
   # Using the helper script (recommended)
   ./view-logs.sh all         # All logs
   ./view-logs.sh server      # Server only
   ./view-logs.sh follow      # Follow in real-time
   
   # Or using podman directly
   podman logs aeos-server
   podman logs aeos-lookup
   podman logs aeos-database
   ```

## Understanding the Build Process

The build process downloads and installs the official AEOS software. See [BUILD.md](BUILD.md) for detailed information about:

- What happens during the build
- Build requirements and timing
- Troubleshooting build issues
- Advanced build options
- Security considerations

**Quick summary:**
- First build takes 10-20 minutes (downloads 1.4GB installer)
- Subsequent builds use cached layers (1-2 minutes)
- Requires ~10GB disk space during build
- Final images are ~4GB total

**After building:** See [POST_BUILD.md](POST_BUILD.md) for next steps, including how to understand build output, handle warnings, and start your containers.

## Container Management

### Start containers:
```bash
docker-compose up -d         # Docker
podman-compose up -d         # Podman
```

### Stop containers:
```bash
docker-compose down          # Docker
podman-compose down          # Podman
```

### View logs:
```bash
docker-compose logs -f aeos-server    # Docker
podman logs -f aeos-server            # Podman
```

### Restart a service:
```bash
docker-compose restart aeos-server    # Docker
podman restart aeos-server            # Podman
```

## Configuration

### Environment Variables

Key environment variables in `.env`:

- `AEOS_DB_PASSWORD` - PostgreSQL database password (required)
- `TZ` - Timezone (default: UTC)
- Port configurations (optional overrides)

### Database Connection

The application server automatically waits for the database to be ready before starting. Connection settings are configured via environment variables.

### Persistent Data

Data is stored in Docker/Podman volumes:
- `aeos-db-data` - Database files
- `aeos-data` - Application data
- `aeos-logs` - Application logs

### Backup Data:
```bash
# Backup database
docker exec aeos-database pg_dump -U aeos aeos > aeos-backup.sql

# Backup volumes
docker run --rm -v aeos-db-data:/data -v $(pwd):/backup alpine tar czf /backup/aeos-data-backup.tar.gz /data
```

### Restore Data:
```bash
# Restore database
cat aeos-backup.sql | docker exec -i aeos-database psql -U aeos aeos
```

## Network Ports

The following ports are exposed:

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| AEOS Web UI | 8080 | HTTP | Web interface |
| AEOS Web UI | 8443 | HTTPS | Secure web interface |
| Lookup Server | 2505 | TCP | Network coordination |
| Application Server | 2506 | TCP | Application services |
| PostgreSQL | 5432 | TCP | Database access |

## Podman-Specific Notes

### Running as Non-Root

Podman can run containers as a non-root user:

```bash
# Run rootless containers
podman-compose up -d

# Check rootless status
podman info | grep rootless
```

### Using Podman Pods

You can also deploy as a Podman pod:

```bash
# Create a pod
podman pod create --name aeos-pod -p 8080:8080 -p 8443:8443 -p 2505:2505

# Run containers in the pod
podman run -d --pod aeos-pod --name aeos-database postgres:14-alpine
podman run -d --pod aeos-pod --name aeos-lookup -e AEOS_DB_HOST=localhost aeos-lookup
podman run -d --pod aeos-pod --name aeos-server -e AEOS_DB_HOST=localhost aeos-server
```

### Systemd Integration

Generate systemd service files for auto-start:

```bash
# Generate systemd files
podman generate systemd --new --files --name aeos-server

# Enable and start
systemctl --user enable container-aeos-server.service
systemctl --user start container-aeos-server.service
```

## Troubleshooting

### View Logs (Helper Script)

A convenient `view-logs.sh` script is provided for easy log access:

```bash
# View all logs
./view-logs.sh all

# View logs from a specific container
./view-logs.sh server     # AEOS application server
./view-logs.sh lookup     # AEOS lookup server
./view-logs.sh database   # PostgreSQL database

# Follow logs in real-time
./view-logs.sh follow

# Check container status
./view-logs.sh status

# Get help
./view-logs.sh help
```

The script automatically detects whether you're using Docker or Podman and adjusts accordingly.

### Container won't start

Check logs:
```bash
docker-compose logs aeos-server
```

Common issues:
- Database not ready: Wait for health checks to pass
- Port conflicts: Change ports in `.env`
- Memory issues: Increase Docker/Podman memory limits

### Database connection errors

1. Verify database is running:
   ```bash
   docker-compose ps aeos-database
   ```

2. Check database logs:
   ```bash
   docker-compose logs aeos-database
   ```

3. Test connection:
   ```bash
   docker exec -it aeos-database psql -U aeos -d aeos
   ```

### Cannot access web interface

1. Check if container is running:
   ```bash
   docker-compose ps
   ```

2. Verify port mappings:
   ```bash
   docker port aeos-server
   ```

3. Check firewall settings:
   ```bash
   sudo ufw allow 8080/tcp
   ```

### Podman-compose healthcheck errors

If you encounter an error like `ValueError: 'CMD_SHELL' takes a single string after it`:

This has been fixed in recent versions. The healthcheck format has been updated to use the `CMD` format which is more compatible with podman-compose:

### Containers stuck in "Created" state with Podman

If containers are built successfully but remain in "Created" state instead of "Running":

**Symptoms:**
- `podman ps` shows containers with status "Created" instead of "Up"
- Database shows "Up" but "unhealthy"
- Lookup and server containers show "Created" status and never start

**Cause:**
- Some versions of podman-compose have a bug where containers are created but not automatically started
- The `up -d` command may not properly start all containers

**Solution (Fixed in this version):**

The `deploy-podman.sh` script has been enhanced with:
1. Explicit container startup commands after `up -d`
2. Database health monitoring (waits up to 60 seconds for database to become healthy)
3. Sequential startup of lookup and server containers
4. Container state verification with detailed logging

If you still experience issues:

**Option 1: Use the updated deployment script**
```bash
./deploy-podman.sh
```

**Option 2: Manually start containers**
```bash
# Start database first
podman start aeos-database

# Wait for database to be healthy (check with)
podman inspect --format='{{.State.Health.Status}}' aeos-database

# Start lookup server
podman start aeos-lookup

# Wait a few seconds
sleep 5

# Start application server
podman start aeos-server

# Verify all are running
podman ps -a --filter "name=aeos-"
```

**Option 3: View logs for debugging**
```bash
# Use the log viewer script
./view-logs.sh status
./view-logs.sh database
./view-logs.sh lookup
./view-logs.sh server
```

If containers fail to start, check the logs using `./view-logs.sh [container-name]` to see error messages.

### Podman Pod cgroup errors

If you encounter an error like:
```
Error: pod <id> cgroup is not set: internal libpod error
Error: "aeos-database" is not a valid container, cannot be used as a dependency
```

**Symptoms:**
- Pod creation fails with cgroup errors
- Containers can't be started due to missing dependencies
- Error messages about containers not being valid

**Cause:**
- Some versions of podman-compose create pods by default
- Pod creation can fail due to cgroup v2 issues or permission problems
- When the pod fails, containers can't be properly created or started

**Solution (Fixed in this version):**

The `deploy-podman.sh` script now:
1. Cleans up any existing pods/containers before deployment
2. Attempts to use `--no-pods` flag if available (avoids pod creation)
3. Manually verifies and starts containers if needed

If you still encounter pod issues, you can:

**Option 1: Clean up and redeploy**
```bash
# Clean up everything
podman-compose down
podman pod rm -f $(podman pod ls -q) 2>/dev/null || true
podman rm -f aeos-server aeos-lookup aeos-database 2>/dev/null || true

# Redeploy
./deploy-podman.sh
```

**Option 2: Use native podman (without compose)**
Edit `deploy-podman.sh` and comment out or rename `podman-compose` temporarily:
```bash
# This will force the script to use native podman commands instead
which podman-compose
# If found, temporarily rename it: sudo mv /usr/local/bin/podman-compose /usr/local/bin/podman-compose.bak
```

Then run:
```bash
./deploy-podman.sh
```

This uses native podman commands which don't create pods and avoid the cgroup issue entirely.


```yaml
healthcheck:
  test: ["CMD", "pg_isready", "-U", "aeos"]  # ✓ Correct format
```

Instead of the shell format:
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U aeos"]  # ✗ May cause issues with podman-compose
```

If you have an older version of the repository, pull the latest changes to get the fix.

### Podman-compose network creation errors

If you encounter an error like `Command 'podman network create ... --subnet 172.20.0.0/16 --subnet 172.20.0.0/16 ...' returned non-zero exit status 125`:

This has been fixed. The issue was caused by duplicate subnet parameters when podman-compose tried to create the network. The `podman-compose.yml` file has been updated to remove the explicit IPAM configuration, allowing Podman to automatically assign subnets.

If you have an older version of the repository, pull the latest changes to get the fix.

## Important Notes

### License Requirements

⚠️ **Note**: The actual AEOS software requires a valid license from Nedap Security Management. This containerized setup provides the infrastructure, but you need to:

1. Obtain AEOS software binaries from Nedap
2. Obtain a valid license file
3. Place the license file in the appropriate volume

Contact Nedap Security Management for licensing: https://www.nedapsecurity.com/

### Hardware Integration

The containerized AEOS system can connect to physical door controllers (AEpus) over the network. Ensure:
- Door controllers can reach the lookup server (port 2505)
- Network routing is properly configured
- Firewalls allow necessary traffic

### Production Deployment

For production use:
1. Use HTTPS with valid SSL certificates
2. Set strong database passwords
3. Configure proper backup strategies
4. Implement monitoring and alerting
5. Review and harden security settings
6. Use persistent storage for critical data

## Support and Documentation

- **Original AEOS Documentation**: See `aeos_technical_help_en_compressed.pdf`
- **Nedap Security Management**: https://www.nedapsecurity.com/
- **Container Issues**: Open an issue on this repository

## License

This containerization is provided as-is. AEOS software is proprietary and requires licensing from Nedap Security Management.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with clear description

## Version Information

- **AEOS Version**: 2023.1.x (based on technical documentation)
- **Container Version**: 1.0.0
- **Last Updated**: 2024
