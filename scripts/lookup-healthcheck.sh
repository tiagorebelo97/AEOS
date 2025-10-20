#!/bin/bash

# Health check for AEOS Lookup Server
# Returns 0 if healthy, 1 if unhealthy

# Check if the process is running
if ! pgrep -f "aeoslookup" > /dev/null; then
    echo "UNHEALTHY: AEOS Lookup process not running"
    exit 1
fi

# Check if the port is listening
if ! nc -z localhost ${AEOS_LOOKUP_PORT:-2505} 2>/dev/null; then
    echo "UNHEALTHY: AEOS Lookup not listening on port ${AEOS_LOOKUP_PORT:-2505}"
    exit 1
fi

echo "HEALTHY: AEOS Lookup is running and listening on port ${AEOS_LOOKUP_PORT:-2505}"
exit 0
