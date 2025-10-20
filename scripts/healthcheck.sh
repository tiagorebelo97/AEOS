#!/bin/bash
# AEOS Application Server Health Check Script

# Check if Tomcat is responding
if curl -f -s http://localhost:8080/aeos/health > /dev/null 2>&1; then
    exit 0
fi

# Fallback: Check if Tomcat port is open
if nc -z localhost 8080; then
    exit 0
fi

exit 1
