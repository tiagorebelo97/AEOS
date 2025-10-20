#!/bin/bash
# AEOS Application Server Health Check Script

# Check if WildFly management interface is responding
if curl -f -s http://localhost:9990 > /dev/null 2>&1; then
    exit 0
fi

# Check if AEOS web interface is responding
if curl -f -s http://localhost:8080 > /dev/null 2>&1; then
    exit 0
fi

# Fallback: Check if WildFly HTTP port is open
if nc -z localhost 8080; then
    exit 0
fi

exit 1
