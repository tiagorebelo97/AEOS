#!/bin/bash
set -e

echo "=========================================="
echo "AEOS Server Starting"
echo "=========================================="
echo "AEOS_HOME: ${AEOS_HOME}"
echo "AEOS_SERVER_PORT: ${AEOS_SERVER_PORT}"
echo "Database: ${AEOS_DB_HOST}:${AEOS_DB_PORT}/${AEOS_DB_NAME}"
echo "Lookup Server: ${AEOS_LOOKUP_HOST}:${AEOS_LOOKUP_PORT}"
echo "=========================================="

# Wait for database to be ready
echo "Waiting for database to be ready..."
timeout=60
counter=0
until nc -z ${AEOS_DB_HOST} ${AEOS_DB_PORT} 2>/dev/null; do
    counter=$((counter + 1))
    if [ $counter -gt $timeout ]; then
        echo "ERROR: Database did not become ready in ${timeout} seconds"
        exit 1
    fi
    echo "Waiting for database... ($counter/$timeout)"
    sleep 1
done
echo "✓ Database is ready"

# Wait for lookup server to be ready
echo "Waiting for lookup server to be ready..."
timeout=60
counter=0
until nc -z ${AEOS_LOOKUP_HOST} ${AEOS_LOOKUP_PORT} 2>/dev/null; do
    counter=$((counter + 1))
    if [ $counter -gt $timeout ]; then
        echo "ERROR: Lookup server did not become ready in ${timeout} seconds"
        exit 1
    fi
    echo "Waiting for lookup server... ($counter/$timeout)"
    sleep 1
done
echo "✓ Lookup server is ready"

# Additional wait to ensure all services are fully initialized
sleep 5

# Set database connection properties if configuration file exists
if [ -f "${AEOS_HOME}/config/database.properties" ]; then
    echo "Configuring database connection..."
    sed -i "s/db.host=.*/db.host=${AEOS_DB_HOST}/" "${AEOS_HOME}/config/database.properties" || true
    sed -i "s/db.port=.*/db.port=${AEOS_DB_PORT}/" "${AEOS_HOME}/config/database.properties" || true
    sed -i "s/db.name=.*/db.name=${AEOS_DB_NAME}/" "${AEOS_HOME}/config/database.properties" || true
    sed -i "s/db.user=.*/db.user=${AEOS_DB_USER}/" "${AEOS_HOME}/config/database.properties" || true
    sed -i "s/db.password=.*/db.password=${AEOS_DB_PASSWORD}/" "${AEOS_HOME}/config/database.properties" || true
fi

# Set lookup server connection if configuration file exists
if [ -f "${AEOS_HOME}/config/server.properties" ]; then
    echo "Configuring lookup server connection..."
    sed -i "s/lookup.host=.*/lookup.host=${AEOS_LOOKUP_HOST}/" "${AEOS_HOME}/config/server.properties" || true
    sed -i "s/lookup.port=.*/lookup.port=${AEOS_LOOKUP_PORT}/" "${AEOS_HOME}/config/server.properties" || true
fi

# Start AEOS Server
echo "Starting AEOS Server on port ${AEOS_SERVER_PORT}..."
cd ${AEOS_HOME}

# Execute the command passed to the script
if [ -x "${AEOS_HOME}/bin/aeosserver" ]; then
    exec "${AEOS_HOME}/bin/aeosserver" "$@"
elif [ -x "${AEOS_HOME}/aeosserver.sh" ]; then
    exec "${AEOS_HOME}/aeosserver.sh" "$@"
else
    echo "ERROR: AEOS Server executable not found"
    echo "Searched in:"
    echo "  - ${AEOS_HOME}/bin/aeosserver"
    echo "  - ${AEOS_HOME}/aeosserver.sh"
    echo ""
    echo "Available files in ${AEOS_HOME}:"
    ls -la ${AEOS_HOME}/ || true
    echo ""
    echo "Available files in ${AEOS_HOME}/bin:"
    ls -la ${AEOS_HOME}/bin/ || true
    exit 1
fi
