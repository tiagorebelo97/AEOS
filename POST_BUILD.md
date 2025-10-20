# After Building AEOS Containers - Next Steps

## Understanding Your Build Output

Congratulations! If you see a message like this at the end of your build:

```
AEOS installation complete
--> 96f865ee2f00
STEP 8/15: COPY scripts/entrypoint.sh /usr/local/bin/
...
Successfully tagged localhost/aeos-copilot-make-program-a-container_aeos-server:latest
e530ad56b5f92fe23f7a97a068fca27585688d562fd73a94af0ae66d92d9c240
```

**✅ Your build was SUCCESSFUL!** The AEOS containers are now ready to use.

## About the HEALTHCHECK Warnings

You may see warnings like this during the build:

```
WARN[0276] HEALTHCHECK is not supported for OCI image format and will be ignored. Must use `docker` format
```

### Is This OK?

**✅ YES, these warnings are completely safe to ignore!**

**Why this happens:**
- Podman defaults to OCI image format (Open Container Initiative standard)
- OCI format doesn't support Docker's HEALTHCHECK directive in the image metadata
- The HEALTHCHECK functionality still works at runtime via Podman's own health checking

**What it means:**
- The health check scripts ARE included in your containers
- Health checks WILL work when containers are running
- This is just a format compatibility notice, not an error

**If you want to eliminate these warnings:**
```bash
# Build with Docker format instead of OCI
podman build --format docker -t aeos-server .
```

But this is **not necessary** - the containers work perfectly with OCI format.

## Your Next Steps

Now that the build is complete, here's what to do:

### Step 1: Verify the Build

Check that all images were created successfully:

```bash
# For Podman
podman images | grep aeos

# For Docker
docker images | grep aeos
```

You should see images like:
- `aeos-server:latest` or similar (approximately 3GB)
- `aeos-lookup:latest` or similar (approximately 3GB)
- `postgres:14-alpine` (approximately 200MB)

### Step 2: Configure Environment (If Not Already Done)

If you haven't created a `.env` file yet:

```bash
# Copy the example
cp .env.example .env

# Edit with your settings (IMPORTANT: set secure passwords!)
nano .env
```

Or if you used `deploy-podman.sh` or `start.sh`, this was done automatically with secure random passwords.

### Step 3: Start the Containers

Choose your preferred method:

#### Using Podman Compose (Recommended for Podman users)
```bash
podman-compose up -d
```

#### Using Docker Compose
```bash
docker-compose up -d
```

#### Using the deploy-podman.sh Script (If not already running)
```bash
./deploy-podman.sh
```

#### Using the start.sh Universal Script
```bash
./start.sh
```

### Step 4: Monitor Container Startup

Watch the containers start up and check for any issues:

```bash
# For Podman
podman ps -a
podman logs -f aeos-server

# For Docker
docker-compose ps
docker-compose logs -f
```

**Expected startup sequence:**
1. **aeos-database** starts first (5-10 seconds)
2. **aeos-lookup** starts second (10-15 seconds)
3. **aeos-server** starts last (30-60 seconds for full startup)

The application server takes the longest because it needs to:
- Wait for database to be ready
- Initialize WildFly application server
- Deploy AEOS web application
- Connect to lookup server

### Step 5: Wait for Health Checks

Even though you saw HEALTHCHECK warnings during build, the containers will perform health checks at runtime:

```bash
# Check health status (Podman)
podman ps --format "table {{.Names}}\t{{.Status}}"

# Check health status (Docker)
docker-compose ps
```

Wait until you see:
- **aeos-database**: `Up (healthy)` or similar
- **aeos-lookup**: `Up` 
- **aeos-server**: `Up (healthy)` or similar

This usually takes **2-5 minutes** after starting the containers.

### Step 6: Access AEOS Web Interface

Once the containers are healthy, access AEOS:

**Web Interface:** http://localhost:8080/aeos

**Secure Web:** https://localhost:8443/aeos (self-signed certificate, accept the warning)

**Default Credentials:**
- Username: `admin`
- Password: `admin`

⚠️ **IMPORTANT:** Change the default password on first login!

### Step 7: Verify Everything Works

Run a quick test to verify the deployment:

```bash
# If you have the test script
./test-deployment.sh

# Or manually:
# Test database
podman exec aeos-database pg_isready -U aeos

# Test web interface
curl -I http://localhost:8080/aeos
```

## What If Something Goes Wrong?

### Containers won't start

```bash
# Check why they're not starting
podman ps -a
podman logs aeos-database
podman logs aeos-lookup
podman logs aeos-server
```

Common issues:
- **Port conflicts**: Another service is using ports 8080, 8443, 2505, 2506, or 5432
  - Solution: Change ports in `.env` or stop conflicting services
- **Out of memory**: System doesn't have enough RAM
  - Solution: Close other applications or increase system memory
- **Database not ready**: Application server starting before database
  - Solution: Wait longer; the entrypoint script automatically retries

### Database connection errors

```bash
# Check database is running
podman ps | grep aeos-database

# Test database connection
podman exec aeos-database pg_isready -U aeos

# Check database logs
podman logs aeos-database
```

### Can't access web interface

```bash
# Check if container is running
podman ps | grep aeos-server

# Check application logs
podman logs aeos-server

# Check if port is open
curl -v http://localhost:8080/aeos

# Test from inside container
podman exec aeos-server curl localhost:8080/aeos
```

### Need to rebuild?

If you need to rebuild after changes:

```bash
# Stop and remove containers
podman-compose down

# Rebuild with no cache
podman-compose build --no-cache

# Start again
podman-compose up -d
```

## Understanding the Build Process

The build you just completed:

1. ✅ Downloaded the official AEOS installer (1.4GB) from GitHub releases
2. ✅ Extracted and installed AEOS to `/opt/aeos` in the container
3. ✅ Configured entrypoint and healthcheck scripts
4. ✅ Set up proper networking and ports
5. ✅ Created production-ready container images

**What's inside the container:**
- Eclipse Temurin Java 11 JDK
- AEOS Application Server (WildFly/JBoss)
- AEOS Libraries and Utilities
- AEOS Web Application
- Configuration and startup scripts

## Performance Notes

### First Run is Slower

The **first time** you start the containers after building:
- Database initialization: 10-20 seconds
- Application deployment: 60-120 seconds
- Total startup time: 2-3 minutes

### Subsequent Runs are Faster

After the first run:
- Database startup: 5-10 seconds
- Application startup: 30-60 seconds
- Total startup time: 1-2 minutes

### System Requirements Check

Ensure your system meets the requirements:

```bash
# Check available memory
free -h

# Check available disk space
df -h

# Check CPU
lscpu | grep "Model name"
```

**Minimum requirements:**
- 8GB RAM (12GB recommended)
- 20GB free disk space
- 4 CPU cores (8 recommended)

## Container Management Commands

### View logs
```bash
# All logs
podman-compose logs -f

# Specific container
podman logs -f aeos-server
podman logs -f aeos-lookup
podman logs -f aeos-database
```

### Restart containers
```bash
# Restart all
podman-compose restart

# Restart specific container
podman restart aeos-server
```

### Stop containers
```bash
# Stop all
podman-compose down

# Stop specific container
podman stop aeos-server
```

### Check container status
```bash
# List all AEOS containers
podman ps -a --filter "name=aeos-"

# Check specific container
podman inspect aeos-server
```

### Execute commands in containers
```bash
# Open shell in application server
podman exec -it aeos-server /bin/bash

# Open database shell
podman exec -it aeos-database psql -U aeos aeos

# Check AEOS version
podman exec aeos-server cat /opt/aeos/version.txt
```

## Data Persistence

Your data is stored in Podman/Docker volumes:

```bash
# List volumes
podman volume ls | grep aeos

# Backup database
podman exec aeos-database pg_dump -U aeos aeos > aeos-backup.sql

# Backup volume
podman volume export aeos-db-data -o aeos-data-backup.tar
```

## Production Considerations

Before using in production:

1. ✅ Change default passwords
2. ✅ Configure HTTPS with valid certificates
3. ✅ Set up regular database backups
4. ✅ Configure firewall rules
5. ✅ Set up monitoring and alerting
6. ✅ Review security settings
7. ✅ Obtain AEOS license from Nedap
8. ✅ Test disaster recovery procedures

## Additional Documentation

- **[README.md](README.md)** - Main project documentation
- **[README_CONTAINER.md](README_CONTAINER.md)** - Detailed container documentation
- **[BUILD.md](BUILD.md)** - Understanding the build process
- **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide
- **[VM_DEPLOYMENT.md](VM_DEPLOYMENT.md)** - Deploy on virtual machines
- **[WORKFLOW.md](WORKFLOW.md)** - Visual workflow documentation

## Getting Help

### Container Issues
- Check logs first: `podman logs aeos-server`
- Review this guide's troubleshooting section
- Check [README_CONTAINER.md](README_CONTAINER.md)
- Open an issue: https://github.com/tiagorebelo97/AEOS/issues

### AEOS Software Issues
- Review the technical documentation: `aeos_technical_help_en_compressed.pdf`
- Contact Nedap Security Management: https://www.nedapsecurity.com/support
- Check AEOS manual for features and configuration

## Summary: You're All Set! 🎉

Your build was successful! To recap:

1. ✅ Build completed successfully
2. ✅ HEALTHCHECK warnings are safe to ignore
3. ✅ Next step: Start the containers with `podman-compose up -d` or your preferred method
4. ✅ Then access AEOS at http://localhost:8080/aeos
5. ✅ Change default credentials on first login

**Welcome to containerized AEOS!**
