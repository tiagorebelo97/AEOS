#!/bin/bash
# AEOS Lookup Server Entrypoint Script

set -e

echo "========================================"
echo "AEOS Lookup Server Starting"
echo "========================================"

# Wait for database to be ready
echo "Waiting for database to be ready..."
while ! nc -z ${AEOS_DB_HOST:-aeos-database} ${AEOS_DB_PORT:-5432}; do
    echo "Database is unavailable - sleeping"
    sleep 2
done
echo "Database is up - continuing"

# Generate lookup.properties from template
if [ -f "${AEOS_LOOKUP_HOME}/config/lookup.properties.template" ]; then
    echo "Generating lookup.properties from template..."
    envsubst < "${AEOS_LOOKUP_HOME}/config/lookup.properties.template" > "${AEOS_LOOKUP_HOME}/config/lookup.properties"
fi

# Set JAVA_OPTS if not already set
export JAVA_OPTS="${JAVA_OPTS:--Xms512m -Xmx1024m}"

echo "========================================"
echo "Lookup Server Configuration:"
echo "  Port: ${AEOS_LOOKUP_PORT:-2505}"
echo "  Database Host: ${AEOS_DB_HOST}"
echo "  Database Port: ${AEOS_DB_PORT}"
echo "========================================"

# Start the lookup server (this is a placeholder - actual implementation would differ)
echo "Starting AEOS Lookup Server on port ${AEOS_LOOKUP_PORT}..."

# Create a simple Java server listener for demonstration
# In a real implementation, this would launch the actual AEOS lookup server
java ${JAVA_OPTS} \
    -Dlookup.port=${AEOS_LOOKUP_PORT} \
    -Dlookup.home=${AEOS_LOOKUP_HOME} \
    -Ddb.host=${AEOS_DB_HOST} \
    -Ddb.port=${AEOS_DB_PORT} \
    -Ddb.name=${AEOS_DB_NAME} \
    -cp "${AEOS_LOOKUP_HOME}/lib/*" \
    com.nedap.aeos.lookup.LookupServer || {
        echo "Note: Actual AEOS lookup server binary not found"
        echo "Creating mock listener on port ${AEOS_LOOKUP_PORT}..."
        # Keep container running with a simple port listener
        nc -l -p ${AEOS_LOOKUP_PORT} -k
    }
