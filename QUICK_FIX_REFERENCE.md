# Quick Fix Reference for Podman Hang Issue

## What Was Fixed

Your deployment script was hanging indefinitely without error messages. This has been fixed by adding timeout protection to all podman commands.

## How to Use

### Normal Deployment
```bash
./start.sh
```

The script will now:
- Complete within a reasonable time (2-5 minutes)
- Show progress messages as it runs
- Display warnings if any issues occur
- Show container logs if something fails
- **Never hang indefinitely**

### Debug Mode (If You Have Issues)
```bash
./start.sh --verbose
```

This shows all commands as they execute, useful for debugging.

## What Changed

1. **All podman commands have timeouts**: No command can hang forever
2. **Better error messages**: You'll see what went wrong and where
3. **Automatic log display**: Logs shown when containers fail
4. **Health check improvements**: Database gets 60 seconds to initialize
5. **Graceful recovery**: Script continues even if some checks fail

## Expected Output

### Successful Deployment
```
🚀 Starting AEOS with Podman...
✓ Using Podman
Cleaning up any existing AEOS containers and pods...
Building containers with podman-compose...
Starting containers with podman-compose...

Ensuring containers are started...
  Checking aeos-database...
  ✓ aeos-database is already running
  Checking aeos-lookup...
  ✓ aeos-lookup is already running
  Checking aeos-server...
  ✓ aeos-server is already running

Waiting for database to be healthy...
  ✓ Database is healthy

Verifying container states...
  ✓ aeos-database is running (health: healthy)
  ✓ aeos-lookup is running (health: healthy)
  ✓ aeos-server is running (health: healthy)

AEOS Deployment Complete!
```

### If Database Stays Unhealthy
You'll now see:
```
⚠️  Warning: Database did not become healthy within timeout period
Current state: running, health: unhealthy
Checking database logs for issues...

[Database logs displayed here]

The database might still be initializing. Continuing anyway...
You can check status with: podman logs -f aeos-database
```

The script will continue instead of hanging!

### If Container Fails to Start
```
  Starting aeos-lookup (current state: created)...
  Retry 1/3 for aeos-lookup...
  Retry 2/3 for aeos-lookup...
  ✗ Failed to start aeos-lookup after 3 attempts
  Checking container logs for errors...
  
  [Container logs displayed here]
```

You'll see the actual error instead of a hang!

## Troubleshooting Commands

If you see warnings, use these commands to investigate:

```bash
# Check container status
podman ps -a --filter "name=aeos-"

# View database logs
podman logs -f aeos-database

# View lookup server logs
podman logs -f aeos-lookup

# View application server logs
podman logs -f aeos-server

# Check container health
podman inspect aeos-database --format='{{.State.Health.Status}}'

# Restart a container
podman restart aeos-database

# Complete reset
podman-compose down
./start.sh
```

## Common Issues and Solutions

### Issue: Database stays unhealthy
**Solution**: Check database logs for initialization errors:
```bash
podman logs aeos-database
```

Common causes:
- Init script taking too long
- Permissions issues
- Disk space issues

### Issue: Container fails to start
**Solution**: The script will show logs automatically. Look for:
- Port conflicts (another service using same port)
- Volume mount issues
- Missing dependencies

### Issue: Script still seems slow
**Normal**: First run builds containers (5-10 minutes)
**After first run**: Should complete in 1-2 minutes

Use `./start.sh --verbose` to see exactly what's taking time.

## What to Do If You Still Have Issues

1. **Run with verbose mode**:
   ```bash
   ./start.sh --verbose
   ```

2. **Check the logs** (now displayed automatically when failures occur)

3. **Try a clean restart**:
   ```bash
   podman-compose down
   podman system prune -f
   ./start.sh
   ```

4. **Check system resources**:
   ```bash
   df -h          # Disk space
   free -h        # Memory
   podman info    # Podman status
   ```

## Getting Help

If you still have issues after these fixes:

1. Run `./start.sh --verbose > deployment.log 2>&1`
2. Share the `deployment.log` file
3. Include output of `podman ps -a --filter "name=aeos-"`
4. Include output of `podman logs aeos-database`

The verbose output will show exactly where the deployment is failing.

## Summary

**Before this fix**: Script hung forever with no output
**After this fix**: Script always completes with clear status

You should now be able to deploy AEOS successfully or at least see clear error messages if something is wrong!
