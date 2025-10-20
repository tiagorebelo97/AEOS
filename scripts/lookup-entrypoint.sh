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

# Start the lookup server
echo "Starting AEOS Lookup Server on port ${AEOS_LOOKUP_PORT}..."

# Find the main JAR file
LOOKUP_JAR=$(find ${AEOS_LOOKUP_HOME}/bin -name "*.jar" -type f | head -n 1)

if [ -n "$LOOKUP_JAR" ] && [ -f "$LOOKUP_JAR" ]; then
    echo "Found lookup server JAR: $LOOKUP_JAR"
    
    # Build classpath with all JARs in bin directory
    CLASSPATH="${AEOS_LOOKUP_HOME}/bin/*"
    
    # Start the actual AEOS lookup server
    exec java ${JAVA_OPTS} \
        -Dlookup.port=${AEOS_LOOKUP_PORT} \
        -Dlookup.home=${AEOS_LOOKUP_HOME} \
        -Dlookup.config=${AEOS_LOOKUP_HOME}/config/lookup.properties \
        -Ddb.host=${AEOS_DB_HOST} \
        -Ddb.port=${AEOS_DB_PORT} \
        -Ddb.name=${AEOS_DB_NAME} \
        -cp "${CLASSPATH}" \
        -jar "$LOOKUP_JAR"
else
    echo "ERROR: No AEOS lookup server JAR file found in ${AEOS_LOOKUP_HOME}/bin/"
    echo "Please place the AEOS lookup server JAR file in binaries/lookup-server/ before building"
    echo ""
    echo "Creating mock listener on port ${AEOS_LOOKUP_PORT} for testing..."
    # Keep container running with a simple port listener for testing/development
    nc -l -p ${AEOS_LOOKUP_PORT} -k
fi
