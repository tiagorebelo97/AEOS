# AEOS Containerized Deployment

## Overview

This repository contains a containerized version of the **AEOS (Access Control and Security Management System)** by Nedap Security Management. The original AEOS system requires Windows Server installation, but this implementation allows you to run AEOS components in containers using Docker or Podman.

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

Before deploying AEOS, ensure you have:

- **Docker** (version 20.10+) or **Podman** (version 3.0+)
- **Docker Compose** or **Podman Compose**
- Minimum 8GB RAM
- 50GB disk space
- **AEOS Software Binaries** from Nedap Security Management
  - AEOS application server WAR file (e.g., `aeos.war`)
  - AEOS lookup server JAR file (e.g., `aeos-lookup.jar`)
  - Valid AEOS license file or key

### Obtaining AEOS Binaries

⚠️ **Critical Step**: AEOS is proprietary software that requires licensing from Nedap.

1. **Contact Nedap Security Management**: https://www.nedapsecurity.com/
2. **Request AEOS Software**: Ask for the installation package for your version
3. **Extract Binaries**: From the installation package, extract:
   - Application server WAR file (usually named `aeos.war` or similar)
   - Lookup server JAR file (usually named `aeos-lookup.jar` or similar)
   - Any required libraries or dependencies
4. **Obtain License**: Get your license file or license key

For detailed instructions on binary placement, see [binaries/README.md](binaries/README.md).

## Quick Start

### Using Docker Compose

1. **Clone the repository:**
   ```bash
   git clone https://github.com/tiagorebelo97/AEOS.git
   cd AEOS
   ```

2. **Place AEOS binaries:**
   ```bash
   # Copy your AEOS binaries to the correct locations
   cp /path/to/aeos.war binaries/app-server/
   cp /path/to/aeos-lookup.jar binaries/lookup-server/
   
   # Verify binaries are in place
   ls -lh binaries/app-server/
   ls -lh binaries/lookup-server/
   ```
   
   See [binaries/README.md](binaries/README.md) for detailed instructions.

3. **Create environment file:**
   ```bash
   cp .env.example .env
   # Edit .env and set secure passwords
   nano .env
   ```

4. **Build the container images:**
   ```bash
   docker-compose build
   ```
   
   This step copies your binaries into the container images.

5. **Start the containers:**
   ```bash
   docker-compose up -d
   ```

6. **Check container status:**
   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

7. **Access AEOS:**
   - Web Interface: http://localhost:8080/aeos
   - HTTPS: https://localhost:8443/aeos
   - Default credentials: admin/admin (change on first login)

### Using Podman

1. **Clone the repository:**
   ```bash
   git clone https://github.com/tiagorebelo97/AEOS.git
   cd AEOS
   ```

2. **Place AEOS binaries:**
   ```bash
   # Copy your AEOS binaries to the correct locations
   cp /path/to/aeos.war binaries/app-server/
   cp /path/to/aeos-lookup.jar binaries/lookup-server/
   ```

3. **Create environment file:**
   ```bash
   cp .env.example .env
   nano .env
   ```

4. **Build and start with Podman:**
   ```bash
   # Using podman-compose
   podman-compose build
   podman-compose up -d
   
   # OR using the deployment script
   ./deploy-podman.sh
   ```

5. **Check pod status:**
   ```bash
   podman ps -a
   podman logs aeos-server
   podman logs aeos-lookup
   podman logs aeos-database
   ```

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
