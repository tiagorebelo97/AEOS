#!/bin/bash

# Health check for AEOS Server
# Returns 0 if healthy, 1 if unhealthy

# Check if the process is running
if ! pgrep -f "aeosserver" > /dev/null; then
    echo "UNHEALTHY: AEOS Server process not running"
    exit 1
fi

# Check if the main port is listening
if ! nc -z localhost ${AEOS_SERVER_PORT:-2506} 2>/dev/null; then
    echo "UNHEALTHY: AEOS Server not listening on port ${AEOS_SERVER_PORT:-2506}"
    exit 1
fi

# Optional: Check web ports
# Uncomment if web interface should be checked
# if ! nc -z localhost 8080 2>/dev/null; then
#     echo "WARNING: AEOS Server web interface not listening on port 8080"
# fi

echo "HEALTHY: AEOS Server is running and listening on port ${AEOS_SERVER_PORT:-2506}"
exit 0
