#!/bin/bash
# AEOS Lookup Server Health Check Script

# Check if lookup server port is open and responding
if nc -z localhost ${AEOS_LOOKUP_PORT:-2505}; then
    exit 0
fi

exit 1
