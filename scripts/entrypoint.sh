#!/bin/bash
# AEOS Application Server Entrypoint Script

set -e

echo "========================================"
echo "AEOS Application Server Starting"
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

# Wait for lookup server to be ready
echo "Waiting for lookup server to be ready..."
LOOKUP_HOST="${AEOS_LOOKUP_HOST:-aeos-lookup}"
LOOKUP_PORT="${AEOS_LOOKUP_PORT:-2505}"
while ! nc -z "${LOOKUP_HOST}" "${LOOKUP_PORT}"; do
    echo "Lookup server ${LOOKUP_HOST}:${LOOKUP_PORT} is unavailable - sleeping"
    sleep 2
done
echo "Lookup server is up - continuing"

# Source AEOS configuration if it exists
if [ -f "${AEOS_HOME}/etc/aeos.cfg" ]; then
    echo "Loading AEOS configuration..."
    . "${AEOS_HOME}/etc/aeos.cfg"
fi

# Configure database connection in AEOS properties
AEOS_PROPS="${AEOS_HOME}/AEserver/standalone/configuration/aeos.properties"
if [ -f "${AEOS_PROPS}" ]; then
    echo "Configuring database connection..."
    sed -i "s/^db.host=.*/db.host=${DB_HOST}/" "${AEOS_PROPS}" || echo "db.host=${DB_HOST}" >> "${AEOS_PROPS}"
    sed -i "s/^db.port=.*/db.port=${DB_PORT}/" "${AEOS_PROPS}" || echo "db.port=${DB_PORT}" >> "${AEOS_PROPS}"
    sed -i "s/^db.name=.*/db.name=${AEOS_DB_NAME:-aeos}/" "${AEOS_PROPS}" || echo "db.name=${AEOS_DB_NAME:-aeos}" >> "${AEOS_PROPS}"
    sed -i "s/^db.user=.*/db.user=${AEOS_DB_USER:-aeos}/" "${AEOS_PROPS}" || echo "db.user=${AEOS_DB_USER:-aeos}" >> "${AEOS_PROPS}"
    sed -i "s/^db.password=.*/db.password=${AEOS_DB_PASSWORD}/" "${AEOS_PROPS}" || echo "db.password=${AEOS_DB_PASSWORD}" >> "${AEOS_PROPS}"
fi

# Set JAVA_OPTS if not already set
export JAVA_OPTS="${JAVA_OPTS:--Xms2048m -Xmx4096m}"

# Add AEOS specific Java options
export JAVA_OPTS="${JAVA_OPTS} -Daeos.home=${AEOS_HOME}"

echo "========================================"
echo "AEOS Configuration:"
echo "  AEOS Home: ${AEOS_HOME}"
echo "  Database Host: ${DB_HOST}"
echo "  Database Port: ${DB_PORT}"
echo "  Database Name: ${AEOS_DB_NAME:-aeos}"
echo "  Database User: ${AEOS_DB_USER:-aeos}"
echo "  Lookup Host: ${LOOKUP_HOST}"
echo "  Lookup Port: ${LOOKUP_PORT}"
echo "  Web Port: ${AEOS_WEB_PORT:-8080}"
echo "  HTTPS Port: ${AEOS_HTTPS_PORT:-8443}"
echo "  Server Port: ${AEOS_SERVER_PORT:-2506}"
echo "========================================"

# Start AEOS Application Server (WildFly/JBoss)
echo "Starting AEOS Application Server..."
if [ "$1" = "run" ]; then
    # Start WildFly in standalone mode
    exec "${AEOS_HOME}/AEserver/bin/standalone.sh" -b 0.0.0.0 -bmanagement 0.0.0.0
else
    exec "$@"
fi
