# Container Startup Issues - Resolution

## Issues Identified

Based on the problem statement, the containers were experiencing the following issues:

1. **aeos-database**: Running but **unhealthy**
2. **aeos-lookup**: In **Created** state (not running)
3. **aeos-server**: In **Created** state (not running)

## Root Causes and Solutions

### 1. Database Health Check Issue

**Problem**: The PostgreSQL container was running but marked as unhealthy.

**Solution**: Improved health check configuration in `docker-compose.yml`:
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U aeos -d aeos"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 10s  # Give database time to initialize
```

**Key improvements**:
- Using proper PostgreSQL health check command
- Adjusted timing to allow for initialization
- Proper retry logic

### 2. Lookup Server Not Starting

**Problem**: The lookup container was created but never started running.

**Root causes**:
- Missing or incorrect entrypoint script
- No wait mechanism for database readiness
- Improper dependency configuration

**Solutions**:

a) **Created proper entrypoint script** (`scripts/lookup-entrypoint.sh`):
   - Waits for database to be ready before starting
   - Configures database connection dynamically
   - Provides clear error messages and diagnostics
   - Lists available executables if startup fails

b) **Added dependency in docker-compose.yml**:
   ```yaml
   depends_on:
     aeos-database:
       condition: service_healthy  # Wait for DB to be healthy
   ```

c) **Created health check** (`scripts/lookup-healthcheck.sh`):
   - Verifies process is running
   - Checks port availability
   - Provides clear status messages

### 3. Application Server Not Starting

**Problem**: The server container was created but never started running.

**Root causes**:
- Missing dependencies (database and lookup server)
- No wait mechanism for required services
- Missing entrypoint script

**Solutions**:

a) **Created proper entrypoint script** (`scripts/entrypoint.sh`):
   - Waits for both database AND lookup server
   - Sequential startup ensures proper initialization
   - Dynamic configuration of connection settings
   - Diagnostic output for troubleshooting

b) **Added proper dependencies in docker-compose.yml**:
   ```yaml
   depends_on:
     aeos-database:
       condition: service_healthy  # Wait for DB
     aeos-lookup:
       condition: service_started  # Wait for lookup
   ```

c) **Created health check** (`scripts/healthcheck.sh`):
   - Verifies server process is running
   - Checks port availability

## Key Features of the Solution

### 1. Robust Startup Sequence

```
1. Database starts and initializes
2. Health check ensures database is ready
3. Lookup server starts (after DB is healthy)
4. Lookup server becomes ready
5. Application server starts (after DB is healthy and lookup is started)
```

### 2. Wait Mechanisms

All entrypoint scripts include:
- Database connectivity checks using `nc -z`
- Configurable timeouts (60 seconds by default)
- Clear progress messages
- Error handling and diagnostics

Example from `lookup-entrypoint.sh`:
```bash
timeout=60
counter=0
until nc -z ${AEOS_DB_HOST} ${AEOS_DB_PORT} 2>/dev/null; do
    counter=$((counter + 1))
    if [ $counter -gt $timeout ]; then
        echo "ERROR: Database did not become ready in ${timeout} seconds"
        exit 1
    fi
    echo "Waiting for database... ($counter/$timeout)"
    sleep 1
done
```

### 3. Dynamic Configuration

The entrypoint scripts automatically configure:
- Database connection parameters
- Service ports
- Inter-service communication

### 4. Comprehensive Diagnostics

When containers fail to start, the scripts now:
- Show what they're looking for
- List available files and directories
- Provide clear error messages
- Suggest next steps

### 5. Easy Deployment

The `start.sh` script:
- Auto-detects Docker or Podman
- Creates secure passwords automatically
- Provides clear status information
- Shows how to access logs and check health
- Lists all useful commands

## Troubleshooting Resources

Two comprehensive guides have been created:

### 1. TROUBLESHOOTING.md
Complete troubleshooting guide with:
- Quick diagnostic commands
- Common issues and solutions
- Log locations (both container and application logs)
- Advanced debugging techniques
- Step-by-step resolution guides

### 2. CONTAINERIZATION.md
Complete documentation including:
- Architecture overview
- Quick start guide
- Configuration options
- Management commands
- Backup and restore procedures
- Performance tuning

## How to Use

### Quick Start
```bash
./start.sh
```

### Check Status
```bash
docker-compose ps
# or
podman-compose ps
```

### View Logs (as requested in problem statement)
```bash
# All services
docker-compose logs -f

# Individual services
docker-compose logs -f aeos-database
docker-compose logs -f aeos-lookup
docker-compose logs -f aeos-server

# Or with podman
podman-compose logs -f aeos-database
podman logs -f aeos-database
```

### Check Health
```bash
docker inspect aeos-database --format '{{.State.Health.Status}}'
docker inspect aeos-lookup --format '{{.State.Health.Status}}'
docker inspect aeos-server --format '{{.State.Health.Status}}'
```

### Access Application Logs Inside Containers
```bash
# List logs
docker exec aeos-server ls -la /opt/aeos/logs/

# View logs
docker exec aeos-server cat /opt/aeos/logs/server.log
docker exec aeos-lookup cat /opt/aeos/logs/lookup.log

# Tail logs
docker exec aeos-server tail -f /opt/aeos/logs/server.log
```

## Expected Behavior After Fix

With these changes, the containers should:

1. **aeos-database**: Start and become **healthy** within 10-30 seconds
2. **aeos-lookup**: Start and run after database is healthy
3. **aeos-server**: Start and run after both database and lookup are ready

All containers should show status **Up** (not just "Created").

## Testing Recommendations

1. Start with a clean slate:
   ```bash
   docker-compose down -v
   ```

2. Run the start script:
   ```bash
   ./start.sh
   ```

3. Monitor the startup:
   ```bash
   docker-compose logs -f
   ```

4. Check final status:
   ```bash
   docker-compose ps
   ```

Expected output:
```
NAME            STATUS                    PORTS
aeos-database   Up (healthy)             0.0.0.0:5432->5432/tcp
aeos-lookup     Up                       0.0.0.0:2505->2505/tcp
aeos-server     Up                       0.0.0.0:2506->2506/tcp, ...
```

## Summary

The containerization solution addresses all the issues mentioned in the problem statement:

✅ **Fixes database health issues** with proper health checks and initialization time
✅ **Ensures containers start properly** with robust entrypoint scripts and wait mechanisms
✅ **Provides log access** as requested - multiple ways to view logs (see TROUBLESHOOTING.md)
✅ **Includes troubleshooting guide** with detailed suggestions for common issues
✅ **Works with both Docker and Podman** as shown in the original problem statement
✅ **Provides easy deployment** with a single start.sh command
✅ **Includes comprehensive documentation** for ongoing maintenance and debugging
