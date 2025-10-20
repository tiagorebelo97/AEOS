#!/bin/bash
# AEOS Lookup Server Entrypoint Script

set -e

echo "========================================"
echo "AEOS Lookup Server Starting"
echo "AEOS Version: 2023.1.8"
echo "========================================"

# Wait for database to be ready
echo "Waiting for database to be ready..."
DB_HOST="${AEOS_DB_HOST:-aeos-database}"
DB_PORT="${AEOS_DB_PORT:-5432}"
while ! nc -z "${DB_HOST}" "${DB_PORT}"; do
    echo "Database ${DB_HOST}:${DB_PORT} is unavailable - sleeping"
    sleep 2
done
echo "Database is up - continuing"

# Source AEOS configuration if it exists
if [ -f "${AEOS_HOME}/etc/aeos.cfg" ]; then
    echo "Loading AEOS configuration..."
    . "${AEOS_HOME}/etc/aeos.cfg"
fi

# Set JAVA_OPTS if not already set
export JAVA_OPTS="${JAVA_OPTS:--Xms512m -Xmx1024m}"

echo "========================================"
echo "Lookup Server Configuration:"
echo "  AEOS Home: ${AEOS_HOME}"
echo "  Port: ${AEOS_LOOKUP_PORT:-2505}"
echo "  Database Host: ${DB_HOST}"
echo "  Database Port: ${DB_PORT}"
echo "  Database Name: ${AEOS_DB_NAME:-aeos}"
echo "========================================"

# Start the AEOS Jini/Lookup Server
echo "Starting AEOS Lookup Server (Jini)..."

# The lookup server is part of the AEOS installation
# It uses the Jini technology for service discovery
if [ "$1" = "start" ] || [ -z "$1" ]; then
    if [ -x "${AEOS_HOME}/bin/jini" ]; then
        exec "${AEOS_HOME}/bin/jini"
    else
        echo "ERROR: AEOS Jini/Lookup server not found at ${AEOS_HOME}/bin/jini"
        echo "Keeping container alive for debugging..."
        tail -f /dev/null
    fi
else
    exec "$@"
fi
