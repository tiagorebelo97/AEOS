# Database Container Healthcheck Fix - Summary

## Problem Statement

Users reported that:
1. Scripts continue to hang during deployment
2. Database container shows "unhealthy" status
3. Dependent services (lookup and server) fail to start properly

## Root Cause Analysis

The issue was identified in the `docker-compose.yml` file. While `podman-compose.yml` had been previously updated with proper healthcheck `start_period` parameters, `docker-compose.yml` was missing these critical settings.

### What is `start_period`?

The `start_period` parameter in Docker/Podman healthchecks defines a grace period during which health check failures won't count towards the retry limit. This is crucial for services that need initialization time before they can respond to health checks.

### The Problem

**In docker-compose.yml (BEFORE the fix):**
- Database healthcheck: **NO** `start_period` → Health checks started immediately
- Lookup server healthcheck: **NO** `start_period` → Health checks started immediately  
- Server healthcheck: `start_period: 60s` (but should be 120s to match podman-compose.yml)

**In podman-compose.yml (already fixed in previous updates):**
- Database healthcheck: `start_period: 60s` ✓
- Lookup server healthcheck: `start_period: 40s` ✓
- Server healthcheck: `start_period: 120s` ✓

### Why This Caused Hanging

1. **Database marked unhealthy immediately**: Without `start_period`, the PostgreSQL container would be marked unhealthy before it could complete initialization (running init scripts, setting up schemas, etc.)

2. **Dependent services blocked**: The `docker-compose.yml` uses `condition: service_healthy` for dependent services:
   ```yaml
   aeos-lookup:
     depends_on:
       aeos-database:
         condition: service_healthy  # Waits forever if DB never becomes healthy
   ```

3. **Cascading failure**: Since the database never became healthy, lookup server wouldn't start, and the application server wouldn't start either.

4. **Scripts hang**: The deployment scripts would wait indefinitely for containers to become healthy, with no timeout or error message.

## Solution Implemented

Updated `docker-compose.yml` to match the healthcheck configuration in `podman-compose.yml`:

### Changes Made

| Service | Parameter | Old Value | New Value | Reason |
|---------|-----------|-----------|-----------|--------|
| aeos-database | start_period | *(missing)* | 60s | Allow time for DB initialization and schema creation |
| aeos-lookup | start_period | *(missing)* | 40s | Allow time for Java/Jini service startup |
| aeos-server | start_period | 60s | 120s | Increase time for WildFly application server startup (large Java app) |

### Complete Healthcheck Configuration

**Database (PostgreSQL):**
```yaml
healthcheck:
  test: ["CMD", "pg_isready", "-U", "aeos"]
  interval: 10s      # Check every 10 seconds
  timeout: 5s        # Each check times out after 5 seconds
  retries: 5         # Mark unhealthy after 5 consecutive failures
  start_period: 60s  # NEW: Grace period for initialization
```

**Lookup Server:**
```yaml
healthcheck:
  test: ["CMD", "nc", "-z", "localhost", "2505"]
  interval: 30s      # Check every 30 seconds
  timeout: 10s       # Each check times out after 10 seconds
  retries: 3         # Mark unhealthy after 3 consecutive failures
  start_period: 40s  # NEW: Grace period for Java service startup
```

**Application Server:**
```yaml
healthcheck:
  test: ["CMD", "/usr/local/bin/healthcheck.sh"]
  interval: 30s       # Check every 30 seconds
  timeout: 10s        # Each check times out after 10 seconds
  retries: 3          # Mark unhealthy after 3 consecutive failures
  start_period: 120s  # UPDATED: Extended grace period for WildFly
```

## How This Fixes the Problem

### Before:
1. `docker-compose up -d` starts all containers
2. Database healthcheck runs immediately (no grace period)
3. Database initialization scripts are still running → healthcheck fails
4. Database marked "unhealthy" before initialization completes
5. Lookup server waits forever for database to become healthy
6. Application server waits forever for database to become healthy
7. **Deployment hangs indefinitely** ❌

### After:
1. `docker-compose up -d` starts all containers
2. Database healthcheck **waits 60 seconds** before counting failures (grace period)
3. Database initialization scripts complete during grace period
4. First real healthcheck runs → succeeds ✓
5. Database marked "healthy"
6. Lookup server starts (waits 40s grace period, then becomes healthy)
7. Application server starts (waits 120s grace period, then becomes healthy)
8. **Deployment completes successfully** ✓

## Benefits

1. **No more hanging**: Containers have adequate time to initialize
2. **Consistent behavior**: docker-compose.yml now matches podman-compose.yml
3. **Better reliability**: Services don't fail health checks during normal startup
4. **Proper dependencies**: Service health properly cascades (DB → Lookup → Server)
5. **No code changes**: Only configuration changes, no application code modified

## Testing Performed

1. ✅ YAML syntax validation (both compose files)
2. ✅ Shell script syntax validation (all scripts)
3. ✅ Security scan (CodeQL) - no issues detected
4. ✅ Configuration consistency verified between docker-compose.yml and podman-compose.yml

## Files Modified

- `docker-compose.yml` - Added/updated healthcheck `start_period` parameters (3 lines changed)

## No Breaking Changes

This fix is completely backward compatible:
- No changes to environment variables
- No changes to ports or networking
- No changes to volumes or data storage
- No changes to container images or builds
- Only adds grace periods to existing healthchecks

## User Action Required

**For Docker users:**
1. Pull the latest changes: `git pull`
2. Restart the deployment: `./start.sh`
3. Containers should now start properly without hanging

**For Podman users:**
- No action needed - podman-compose.yml was already correct

## Verification Steps

After applying this fix, users can verify successful deployment:

```bash
# Start the deployment
./start.sh

# Check container health status (should show "healthy" after ~2 minutes)
docker ps --format "table {{.Names}}\t{{.Status}}"

# Expected output:
# aeos-database   Up 2 minutes (healthy)
# aeos-lookup     Up 2 minutes (healthy)  
# aeos-server     Up 2 minutes (healthy)

# View logs if needed
docker-compose logs -f
```

## Related Documentation

- Previous fix: `PODMAN_HANG_FIX.md` - Addressed timeout issues in deploy-podman.sh
- Previous fix: `CONTAINER_FIX_SUMMARY.md` - Addressed container startup sequencing
- This fix: Addresses the root cause in docker-compose.yml healthcheck configuration

## Timeline

- **Before**: Database immediately marked unhealthy → deployment hangs
- **Now**: Database gets 60s grace period → becomes healthy → deployment succeeds

The fix ensures that Docker healthchecks give services adequate time to initialize, preventing premature "unhealthy" status that blocks dependent services.
