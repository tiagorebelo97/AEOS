#!/bin/bash
# AEOS Container Quick Start Guide
# This script helps you get started with the fixed AEOS container deployment

cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║           AEOS Container Deployment - Quick Guide            ║
╚═══════════════════════════════════════════════════════════════╝

🚀 QUICK START
══════════════════════════════════════════════════════════════

1. Deploy AEOS (This handles everything automatically):
   ./deploy-podman.sh

   OR if you have Docker:
   ./start.sh

2. Check Container Status:
   ./view-logs.sh status

3. View Logs:
   ./view-logs.sh all         # All logs
   ./view-logs.sh server      # Server logs only
   ./view-logs.sh lookup      # Lookup server logs only
   ./view-logs.sh database    # Database logs only
   ./view-logs.sh follow      # Follow all logs in real-time


📋 WHAT THE FIX ADDRESSES
══════════════════════════════════════════════════════════════

Previous Issue:
✗ Containers stuck in "Created" state
✗ Database showing "unhealthy"
✗ Lookup and server containers not starting

Fixed:
✓ Containers now start automatically in correct sequence
✓ Database health monitoring (waits until healthy)
✓ Sequential startup: database → lookup → server
✓ Automatic verification that all containers are running
✓ Better error messages and logging


🔍 TROUBLESHOOTING
══════════════════════════════════════════════════════════════

If containers are still not starting:

1. Check Status:
   ./view-logs.sh status

2. View Logs for Errors:
   ./view-logs.sh database
   ./view-logs.sh lookup
   ./view-logs.sh server

3. Manual Container Start (if needed):
   podman start aeos-database
   # Wait 30-60 seconds for database to become healthy
   podman start aeos-lookup
   sleep 5
   podman start aeos-server

4. Check Individual Container Health:
   podman inspect --format='{{.State.Status}}' aeos-database
   podman inspect --format='{{.State.Health.Status}}' aeos-database

5. Stop and Restart Everything:
   podman-compose down
   ./deploy-podman.sh


📊 VERIFYING DEPLOYMENT
══════════════════════════════════════════════════════════════

All containers should show "Up" or "running" status:

$ podman ps -a --filter "name=aeos-"

Expected output:
- aeos-database: Up X minutes (healthy)
- aeos-lookup:   Up X minutes
- aeos-server:   Up X minutes

If any container shows "Created" instead of "Up", use:
$ podman start <container-name>


🌐 ACCESSING AEOS
══════════════════════════════════════════════════════════════

Once all containers are running:

HTTP:  http://localhost:8080/aeos
HTTPS: https://localhost:8443/aeos

Default credentials: admin/admin (change on first login)


📖 DOCUMENTATION
══════════════════════════════════════════════════════════════

- Full documentation: README_CONTAINER.md
- Fix details: CONTAINER_FIX_SUMMARY.md
- Build info: BUILD.md
- Quick start: QUICKSTART.md


💡 HELPER COMMANDS
══════════════════════════════════════════════════════════════

View this guide:
  ./QUICKSTART_CONTAINER.sh

Check container status:
  ./view-logs.sh status

Follow all logs:
  ./view-logs.sh follow

Stop everything:
  podman-compose down

Restart a specific container:
  podman restart aeos-server

Remove everything and start fresh:
  podman-compose down -v
  ./deploy-podman.sh


🆘 GETTING HELP
══════════════════════════════════════════════════════════════

If you're still experiencing issues:

1. Check the logs: ./view-logs.sh all
2. Check the troubleshooting section in README_CONTAINER.md
3. Review CONTAINER_FIX_SUMMARY.md for technical details
4. Open an issue on GitHub with:
   - Output of: ./view-logs.sh status
   - Relevant logs from: ./view-logs.sh all

══════════════════════════════════════════════════════════════
EOF
