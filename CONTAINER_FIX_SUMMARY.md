# Container Startup Issue Fix - Summary

## Problem
Containers were being created but not started when using `podman-compose`. The symptoms were:
- Database container showed "Up" but "unhealthy"
- Lookup and server containers showed "Created" status instead of "Up/Running"
- `podman-compose up -d` was creating containers but not starting them

## Root Cause
The issue was caused by a bug in some versions of `podman-compose` where:
1. The `up -d` command creates containers but doesn't always start them
2. The original `podman-compose start` workaround wasn't sufficient
3. The script didn't wait for the database to become healthy before starting dependent services

## Solution Implemented

### 1. Enhanced `deploy-podman.sh` Script
**File:** `deploy-podman.sh`

**Changes:**
- Added explicit `podman start` commands for each container
- Implemented database health monitoring (waits up to 60 seconds)
- Added sequential startup: database → lookup → server
- Enhanced container state verification with health status
- Added automatic log output when containers fail to start
- Improved status reporting with detailed container information

**Key improvements:**
```bash
# Before: Simple start command
podman-compose start

# After: Sequential startup with health monitoring
podman start aeos-database
# Wait for database health
podman start aeos-lookup
sleep 3
podman start aeos-server
```

### 2. Updated `podman-compose.yml`
**File:** `podman-compose.yml`

**Changes:**
- Updated healthcheck commands to use `CMD-SHELL` format for better compatibility
- Added `start_period` to healthchecks to give containers time to initialize
- Changed server healthcheck `start_period` from 60s to 120s for slower systems

**Example:**
```yaml
# Before
healthcheck:
  test: ["CMD", "pg_isready", "-U", "aeos"]

# After
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U aeos || exit 1"]
  start_period: 30s
```

### 3. Created Log Viewer Tool
**File:** `view-logs.sh` (NEW)

**Features:**
- Unified interface for viewing container logs
- Works with both Docker and Podman
- Multiple viewing modes:
  - `all` - Show all logs
  - `server`, `lookup`, `database` - Show specific container logs
  - `follow` - Follow logs in real-time
  - `status` - Show container status with health checks

**Usage:**
```bash
./view-logs.sh all         # View all logs
./view-logs.sh server      # View server logs only
./view-logs.sh follow      # Follow all logs in real-time
./view-logs.sh status      # Check container status
```

### 4. Updated Documentation
**File:** `README_CONTAINER.md`

**Changes:**
- Added log viewer documentation
- Enhanced troubleshooting section for "Created" state issue
- Added step-by-step manual recovery instructions
- Updated Quick Start guide to reference log viewer

## Testing
All changes have been validated:
- ✓ Shell script syntax validation (bash -n)
- ✓ YAML syntax validation
- ✓ All entrypoint scripts validated
- ✓ Security scan (no issues detected)

## How Users Can Verify the Fix

### Option 1: Use the Enhanced Deployment Script
```bash
./deploy-podman.sh
```
The script now:
- Explicitly starts each container
- Waits for database to be healthy
- Verifies all containers are running
- Shows logs if any container fails

### Option 2: Check Container Status
```bash
./view-logs.sh status
```

### Option 3: View Logs for Debugging
```bash
./view-logs.sh all
```

## What Changed for Users

### Before:
- Containers stuck in "Created" state
- No easy way to view logs
- Manual intervention required to start containers
- No clear troubleshooting guidance

### After:
- Containers start automatically in correct sequence
- Built-in health monitoring
- Easy log access via `view-logs.sh`
- Comprehensive troubleshooting documentation
- Automatic recovery attempts

## Files Modified
1. `deploy-podman.sh` - Enhanced container startup and verification
2. `podman-compose.yml` - Improved healthcheck compatibility
3. `README_CONTAINER.md` - Added documentation
4. `view-logs.sh` - NEW: Log viewer utility

## No Breaking Changes
All changes are backwards compatible. Users with existing deployments can:
- Pull the latest changes
- Run `./deploy-podman.sh` again
- No data loss or configuration changes required
