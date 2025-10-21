# Quick Fix Guide: Container Startup Issue

## What Was Fixed?

The deployment script now properly starts containers that are created but not running. Previously, containers would be created but remain in "Created" state instead of "Running" state.

## How Does It Work Now?

When you run `./start.sh`, the script will:

1. ✅ Create all containers
2. ✅ Verify each container's state
3. ✅ Automatically start containers that aren't running
4. ✅ Retry up to 3 times if starting fails
5. ✅ Show clear success/failure indicators
6. ✅ Display logs if a container fails to start

## What You'll See

### Successful Start
```
Ensuring containers are started...
  ✓ aeos-database is already running
  Starting aeos-lookup (current state: created)...
  ✓ Successfully started aeos-lookup
  Starting aeos-server (current state: created)...
  ✓ Successfully started aeos-server

Verifying container states...
  ✓ aeos-database is running (health: healthy)
  ✓ aeos-lookup is running (health: none)
  ✓ aeos-server is running (health: none)
```

### Failed Start (with automatic diagnostics)
```
Ensuring containers are started...
  Starting aeos-server (current state: created)...
  Retry 1/3 for aeos-server...
  Retry 2/3 for aeos-server...
  ✗ Failed to start aeos-server after 3 attempts
  Checking container logs for errors...
     [Container logs appear here]

⚠️  Warning: Not all containers are running!
   Please check the logs above for errors.
   You can view full logs with:
     podman logs aeos-database
     podman logs aeos-lookup
     podman logs aeos-server
```

## Verification Commands

Check container status:
```bash
podman ps --filter "name=aeos-"
```

View container logs:
```bash
podman logs aeos-database
podman logs aeos-lookup
podman logs aeos-server
```

View logs in real-time:
```bash
podman logs -f aeos-server
```

## Troubleshooting

If containers still won't start after this fix:

1. **Check the error logs** displayed by the script
2. **Manual start attempt**: `podman start aeos-lookup` or `podman start aeos-server`
3. **Inspect container**: `podman inspect aeos-lookup`
4. **Remove and recreate**: 
   ```bash
   podman stop aeos-lookup aeos-server
   podman rm aeos-lookup aeos-server
   ./start.sh
   ```

## Common Issues Resolved

- ✅ Containers created but not running
- ✅ Silent failures during container start
- ✅ Script completing without actual container startup
- ✅ Lock file conflicts (with retry logic)
- ✅ Timing issues during startup

## Need More Help?

See `CONTAINER_STARTUP_FIX.md` for detailed technical information.
