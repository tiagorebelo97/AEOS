#!/bin/bash
# AEOS Application Server Entrypoint Script

set -e

echo "========================================"
echo "AEOS Application Server Starting"
echo "========================================"

# Wait for database to be ready
echo "Waiting for database to be ready..."
while ! nc -z ${AEOS_DB_HOST:-aeos-database} ${AEOS_DB_PORT:-5432}; do
    echo "Database is unavailable - sleeping"
    sleep 2
done
echo "Database is up - continuing"

# Wait for lookup server to be ready
echo "Waiting for lookup server to be ready..."
while ! nc -z ${AEOS_LOOKUP_HOST:-aeos-lookup} ${AEOS_LOOKUP_PORT:-2505}; do
    echo "Lookup server is unavailable - sleeping"
    sleep 2
done
echo "Lookup server is up - continuing"

# Generate aeos.properties from template
if [ -f "${AEOS_DATA}/config/aeos.properties.template" ]; then
    echo "Generating aeos.properties from template..."
    envsubst < "${AEOS_DATA}/config/aeos.properties.template" > "${AEOS_DATA}/config/aeos.properties"
fi

# Set JAVA_OPTS if not already set
export JAVA_OPTS="${JAVA_OPTS:--Xms2048m -Xmx4096m}"

# Add AEOS specific Java options
export JAVA_OPTS="${JAVA_OPTS} -Daeos.home=${AEOS_HOME}"
export JAVA_OPTS="${JAVA_OPTS} -Daeos.data=${AEOS_DATA}"
export JAVA_OPTS="${JAVA_OPTS} -Daeos.config=${AEOS_DATA}/config"

echo "========================================"
echo "AEOS Configuration:"
echo "  Database Host: ${AEOS_DB_HOST}"
echo "  Database Port: ${AEOS_DB_PORT}"
echo "  Database Name: ${AEOS_DB_NAME}"
echo "  Lookup Host: ${AEOS_LOOKUP_HOST}"
echo "  Lookup Port: ${AEOS_LOOKUP_PORT}"
echo "  Web Port: ${AEOS_WEB_PORT:-8080}"
echo "  HTTPS Port: ${AEOS_HTTPS_PORT:-8443}"
echo "  Server Port: ${AEOS_SERVER_PORT:-2506}"
echo "========================================"

echo "Starting AEOS Application Server..."
exec "$@"
