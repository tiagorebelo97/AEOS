# Container Startup Issue Fix - Summary

## Problem Statement

The AEOS deployment script (`deploy-podman.sh`) was creating containers but not properly starting them. Users reported that after running `./start.sh`, the containers would be in "Created" state instead of "Running" state, preventing the application from functioning.

### Symptoms
- Database container: Running but showing "unhealthy" status
- aeos-lookup container: Status = "Created" (not running)
- aeos-server container: Status = "Created" (not running)
- The deployment script completed without ensuring containers were actually running

## Root Cause Analysis

The issue was in the `deploy_with_compose()` function in `deploy-podman.sh`. The script had logic to start containers that weren't running, but:

1. **Insufficient error handling**: The `podman start` command failures were silently ignored with `2>/dev/null`
2. **No retry mechanism**: If a container failed to start on the first attempt, it would not retry
3. **Premature script completion**: The script would exit successfully even if containers failed to start
4. **Poor visibility**: Users wouldn't know why containers failed to start

## Solution Implemented

### Changes Made to `deploy-podman.sh`

#### 1. Added Retry Logic with Better Error Handling (lines 119-157)

**Before:**
```bash
podman start ${container} 2>/dev/null || {
    echo "  Warning: Failed to start ${container}, it may be in a bad state"
    echo "  Attempting to recreate..."
}
```

**After:**
```bash
# Try to start the container with retries
max_retries=3
retry_count=0
started=false

while [ $retry_count -lt $max_retries ]; do
    if podman start ${container} 2>&1; then
        started=true
        echo "  ✓ Successfully started ${container}"
        break
    else
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo "  Retry $retry_count/$max_retries for ${container}..."
            sleep 2
        fi
    fi
done

if [ "$started" = false ]; then
    echo "  ✗ Failed to start ${container} after $max_retries attempts"
    echo "  Checking container logs for errors..."
    podman logs --tail 20 ${container} 2>&1 | sed 's/^/     /'
fi
```

**Improvements:**
- 3 retry attempts with 2-second delays between retries
- Clear success/failure indicators (✓/✗)
- Automatic log display on persistent failures
- Actual error output visible (using `2>&1` instead of `2>/dev/null`)

#### 2. Enhanced Container Verification (lines 200-224)

**Before:**
```bash
echo "Verifying container states..."
for container in aeos-database aeos-lookup aeos-server; do
    # ... check and log state ...
done
```

**After:**
```bash
echo "Verifying container states..."
all_running=true
for container in aeos-database aeos-lookup aeos-server; do
    # ... check and log state ...
    if [ "$state" != "running" ]; then
        all_running=false
    fi
done

if [ "$all_running" = false ]; then
    echo ""
    echo "⚠️  Warning: Not all containers are running!"
    echo "   Please check the logs above for errors."
    echo "   You can view full logs with:"
    echo "     podman logs aeos-database"
    echo "     podman logs aeos-lookup"
    echo "     podman logs aeos-server"
fi
```

**Improvements:**
- Tracks whether all containers are running
- Provides clear warning if any container failed to start
- Gives users specific commands to investigate issues

## Testing Performed

### 1. Syntax Validation
All bash scripts pass syntax checking:
```bash
✓ deploy-podman.sh
✓ start.sh
✓ scripts/entrypoint.sh
✓ scripts/lookup-entrypoint.sh
✓ scripts/healthcheck.sh
✓ scripts/lookup-healthcheck.sh
```

### 2. Logic Validation
Created and ran test script to verify retry logic works correctly:
- ✓ Container already running: Skips start, reports as running
- ✓ Container starts on first try: Successfully starts
- ✓ Container requires retries: Retries and succeeds
- ✓ Container fails after retries: Reports failure with logs

### 3. Security Analysis
- CodeQL checker: No security issues detected
- No credentials exposed in logs
- Safe error handling without information leakage

## Expected Behavior After Fix

1. **Containers created but not running**: Script will retry up to 3 times with 2-second delays
2. **Clear feedback**: Users see success (✓) or failure (✗) indicators for each container
3. **Automatic diagnostics**: Failed container logs are automatically displayed
4. **Proper warnings**: Script warns users if not all containers are running
5. **Actionable guidance**: Users get specific commands to investigate issues

## Verification Steps for Users

After applying this fix, users should:

1. Run `./start.sh` or `./deploy-podman.sh`
2. Check that all three containers show "✓ is running":
   ```
   ✓ aeos-database is running
   ✓ aeos-lookup is running
   ✓ aeos-server is running
   ```
3. Verify with: `podman ps --filter "name=aeos-"`
4. All containers should show "Up" status, not "Created"

## Additional Notes

- The fix is backward compatible and doesn't change the API or configuration
- No changes required to compose files, Dockerfiles, or entrypoint scripts
- The retry logic handles transient failures (network, timing, etc.)
- Container logs are preserved and accessible for debugging

## Files Modified

- `deploy-podman.sh`: Added retry logic and enhanced error handling (37 additions, 5 deletions)

## Security Summary

No security vulnerabilities were introduced or discovered during this fix. The changes improve error visibility without exposing sensitive information.
