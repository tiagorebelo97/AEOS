#!/bin/bash
# Podman deployment script for AEOS
# This script fully automates AEOS deployment using Podman
# Usage: ./deploy-podman.sh

set -e

echo "=========================================="
echo "AEOS Podman Deployment Script"
echo "=========================================="

# Check if podman is installed
if ! command -v podman &> /dev/null; then
    echo "Error: Podman is not installed"
    echo "Please install podman: https://podman.io/getting-started/installation"
    exit 1
fi

echo "✓ Podman is installed"
podman --version

# Check if podman-compose is installed
if ! command -v podman-compose &> /dev/null; then
    echo "Warning: podman-compose is not installed"
    echo "You can install it with: pip3 install podman-compose"
    echo "Attempting to continue with podman commands..."
    USE_COMPOSE=false
else
    echo "✓ Podman-compose is installed"
    USE_COMPOSE=true
fi

# Function to generate a secure random password
generate_password() {
    # Try different methods to generate a secure password
    if command -v openssl &> /dev/null; then
        openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
    elif command -v pwgen &> /dev/null; then
        pwgen -s 25 1
    else
        # Fallback to /dev/urandom
        cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 25 | head -n 1
    fi
}

# Check for .env file and create if missing
if [ ! -f .env ]; then
    echo "Creating .env file with secure random password..."
    DB_PASSWORD=$(generate_password)
    cat > .env << EOF
# Environment Variables for AEOS Container Setup
# Auto-generated on $(date)

# Database Configuration
AEOS_DB_PASSWORD=${DB_PASSWORD}

# Timezone Configuration
TZ=UTC

# Optional: Custom ports (uncomment to override defaults)
# AEOS_WEB_PORT=8080
# AEOS_HTTPS_PORT=8443
# AEOS_LOOKUP_PORT=2505
# AEOS_SERVER_PORT=2506
# AEOS_DB_PORT=5432
EOF
    echo "✓ Created .env file with secure password"
else
    echo "✓ Using existing .env file"
fi

# Function to deploy with podman-compose
deploy_with_compose() {
    # Clean up any existing containers and pods to avoid conflicts
    echo ""
    echo "Cleaning up any existing AEOS containers and pods..."
    
    # Stop and remove containers if they exist
    for container in aeos-server aeos-lookup aeos-database; do
        if timeout 5 podman ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            echo "  Stopping and removing ${container}..."
            timeout 30 podman stop ${container} 2>/dev/null || true
            timeout 10 podman rm -f ${container} 2>/dev/null || true
        fi
    done
    
    # Remove any AEOS-related pods
    for pod in $(timeout 10 podman pod ls --format '{{.Name}}' | grep -i aeos); do
        echo "  Removing pod ${pod}..."
        timeout 30 podman pod rm -f "${pod}" 2>/dev/null || true
    done
    
    # Also clean up using podman-compose to ensure consistent state
    echo "  Running podman-compose down to clean up..."
    timeout 60 podman-compose down 2>/dev/null || true
    
    echo ""
    echo "Building containers with podman-compose..."
    # Set environment variable to avoid pod creation issues with cgroup v2
    # This tells podman-compose to not use pods which can have cgroup issues
    export PODMAN_USERNS=keep-id
    
    # Try using --no-pods flag if supported, otherwise use regular build
    if podman-compose --help 2>&1 | grep -q -- '--no-pods'; then
        echo "  Using --no-pods flag to avoid pod creation issues..."
        podman-compose --no-pods build
    else
        podman-compose build
    fi
    
    echo ""
    echo "Starting containers with podman-compose..."
    if podman-compose --help 2>&1 | grep -q -- '--no-pods'; then
        podman-compose --no-pods up -d
    else
        podman-compose up -d
    fi
    
    # Explicitly start containers (workaround for podman-compose issues)
    # This ensures containers are started even if pod creation failed
    echo ""
    echo "Ensuring containers are started..."
    
    # Check if containers exist and start them if needed
    for container in aeos-database aeos-lookup aeos-server; do
        echo "  Checking ${container}..."
        if podman ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            # Use timeout to prevent hanging on inspect command
            state=$(timeout 10 podman inspect --format='{{.State.Status}}' ${container} 2>/dev/null || echo "unknown")
            if [ "$state" = "unknown" ]; then
                echo "  ⚠️  Warning: Could not inspect ${container} (command timed out or failed)"
                echo "  Container may be in a bad state. Attempting to remove and let compose recreate..."
                podman rm -f ${container} 2>/dev/null || true
                continue
            fi
            
            if [ "$state" != "running" ]; then
                echo "  Starting ${container} (current state: ${state})..."
                
                # Try to start the container with retries and timeout
                max_retries=3
                retry_count=0
                started=false
                
                while [ $retry_count -lt $max_retries ]; do
                    # Use timeout to prevent hanging on start command
                    if timeout 30 podman start ${container} 2>&1; then
                        started=true
                        echo "  ✓ Successfully started ${container}"
                        break
                    else
                        retry_count=$((retry_count + 1))
                        if [ $retry_count -lt $max_retries ]; then
                            echo "  Retry $retry_count/$max_retries for ${container}..."
                            sleep 2
                        fi
                    fi
                done
                
                if [ "$started" = false ]; then
                    echo "  ✗ Failed to start ${container} after $max_retries attempts"
                    echo "  Checking container logs for errors..."
                    timeout 10 podman logs --tail 20 ${container} 2>&1 | sed 's/^/     /' || echo "     (Could not retrieve logs)"
                fi
            else
                echo "  ✓ ${container} is already running"
            fi
        else
            echo "  Warning: ${container} does not exist, podman-compose may have failed"
        fi
    done
    
    echo ""
    echo "Waiting for database to be healthy (this may take 30-60 seconds)..."
    db_healthy=false
    for i in {1..30}; do
        if ! timeout 5 podman ps --format '{{.Names}}' | grep -q "^aeos-database$"; then
            echo "  Database container not found, waiting..."
            sleep 2
            continue
        fi
        
        health=$(timeout 5 podman inspect --format='{{.State.Health.Status}}' aeos-database 2>/dev/null || echo "none")
        state=$(timeout 5 podman inspect --format='{{.State.Status}}' aeos-database 2>/dev/null || echo "not found")
        
        if [ "$state" != "running" ]; then
            echo "  Database is not running (state: $state), attempting to start..."
            timeout 30 podman start aeos-database 2>/dev/null || true
        fi
        
        if [ "$health" = "healthy" ]; then
            echo "  ✓ Database is healthy"
            db_healthy=true
            break
        fi
        
        echo "  Database health: $health, state: $state (attempt $i/30)"
        sleep 2
    done
    
    # Check if database became healthy
    if [ "$db_healthy" = false ]; then
        echo ""
        echo "  ⚠️  Warning: Database did not become healthy within timeout period"
        echo "  Current state: $state, health: $health"
        echo "  Checking database logs for issues..."
        echo ""
        timeout 10 podman logs --tail 30 aeos-database 2>&1 | sed 's/^/     /' || echo "     (Could not retrieve logs)"
        echo ""
        echo "  The database might still be initializing. Continuing anyway..."
        echo "  You can check status with: podman logs -f aeos-database"
    fi
    
    # Wait a moment for containers to initialize
    echo ""
    echo "Waiting for containers to initialize..."
    sleep 5
    
    echo ""
    echo "Checking container status..."
    timeout 10 podman-compose ps || echo "⚠️  podman-compose ps command timed out or failed"
    
    # Verify containers are running
    echo ""
    echo "Verifying container states..."
    all_running=true
    for container in aeos-database aeos-lookup aeos-server; do
        state=$(timeout 10 podman inspect --format='{{.State.Status}}' ${container} 2>/dev/null || echo "unknown")
        health=$(timeout 10 podman inspect --format='{{.State.Health.Status}}' ${container} 2>/dev/null || echo "none")
        
        if [ "$state" = "running" ]; then
            echo "  ✓ ${container} is running (health: $health)"
        elif [ "$state" = "unknown" ]; then
            echo "  ⚠️  ${container} status could not be determined (command timed out)"
            all_running=false
        else
            echo "  ✗ ${container} is ${state} (health: $health)"
            echo "     Attempting to view logs..."
            timeout 10 podman logs --tail 50 ${container} 2>&1 | sed 's/^/     /' || echo "     (Could not retrieve logs)"
            all_running=false
        fi
    done
    
    if [ "$all_running" = false ]; then
        echo ""
        echo "⚠️  Warning: Not all containers are running!"
        echo "   Please check the logs above for errors."
        echo "   You can view full logs with:"
        echo "     podman logs aeos-database"
        echo "     podman logs aeos-lookup"
        echo "     podman logs aeos-server"
    fi
}

# Function to deploy with native podman
deploy_with_podman() {
    # Clean up any existing containers to avoid conflicts
    echo ""
    echo "Cleaning up any existing AEOS containers..."
    for container in aeos-server aeos-lookup aeos-database; do
        if timeout 5 podman ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            echo "  Stopping and removing ${container}..."
            timeout 30 podman stop ${container} 2>/dev/null || true
            timeout 10 podman rm -f ${container} 2>/dev/null || true
        fi
    done
    
    echo ""
    echo "Creating podman network..."
    timeout 10 podman network create aeos-network || echo "Network already exists"
    
    echo ""
    echo "Creating volumes..."
    timeout 10 podman volume create aeos-db-data || echo "Volume aeos-db-data already exists"
    timeout 10 podman volume create aeos-data || echo "Volume aeos-data already exists"
    timeout 10 podman volume create aeos-logs || echo "Volume aeos-logs already exists"
    
    # Load environment variables
    source .env 2>/dev/null || true
    DB_PASSWORD=${AEOS_DB_PASSWORD:-aeos_password_change_me}
    
    echo ""
    echo "Starting PostgreSQL database..."
    podman run -d \
        --name aeos-database \
        --network aeos-network \
        -e POSTGRES_DB=aeos \
        -e POSTGRES_USER=aeos \
        -e POSTGRES_PASSWORD="${DB_PASSWORD}" \
        -e PGDATA=/var/lib/postgresql/data/pgdata \
        -v aeos-db-data:/var/lib/postgresql/data \
        -v ./init-scripts:/docker-entrypoint-initdb.d:ro \
        -p 5432:5432 \
        --health-cmd "pg_isready -U aeos" \
        --health-interval 10s \
        --health-timeout 5s \
        --health-retries 5 \
        postgres:14-alpine || echo "Database container already exists"
    
    echo "Waiting for database to be healthy..."
    sleep 10
    
    echo ""
    echo "Building AEOS Lookup Server image..."
    podman build -t aeos-lookup:latest -f Dockerfile.lookup .
    
    echo "Starting AEOS Lookup Server..."
    podman run -d \
        --name aeos-lookup \
        --network aeos-network \
        -e AEOS_LOOKUP_PORT=2505 \
        -e AEOS_DB_HOST=aeos-database \
        -e AEOS_DB_PORT=5432 \
        -e AEOS_DB_NAME=aeos \
        -e AEOS_DB_USER=aeos \
        -e AEOS_DB_PASSWORD="${DB_PASSWORD}" \
        -p 2505:2505 \
        aeos-lookup:latest || echo "Lookup server already exists"
    
    echo "Waiting for lookup server to start..."
    sleep 5
    
    echo ""
    echo "Building AEOS Application Server image..."
    podman build -t aeos-server:latest -f Dockerfile .
    
    echo "Starting AEOS Application Server..."
    podman run -d \
        --name aeos-server \
        --network aeos-network \
        -e AEOS_DB_HOST=aeos-database \
        -e AEOS_DB_PORT=5432 \
        -e AEOS_DB_NAME=aeos \
        -e AEOS_DB_USER=aeos \
        -e AEOS_DB_PASSWORD="${DB_PASSWORD}" \
        -e AEOS_LOOKUP_HOST=aeos-lookup \
        -e AEOS_LOOKUP_PORT=2505 \
        -e AEOS_SERVER_PORT=2506 \
        -e AEOS_WEB_PORT=8080 \
        -e AEOS_HTTPS_PORT=8443 \
        -v aeos-data:/var/lib/aeos \
        -v aeos-logs:/opt/aeos/logs \
        -v ./config:/opt/aeos/config:ro \
        -p 8080:8080 \
        -p 8443:8443 \
        -p 2506:2506 \
        aeos-server:latest || echo "Application server already exists"
    
    echo ""
    echo "Checking container status..."
    timeout 10 podman ps -a --filter "name=aeos-" || echo "⚠️  Could not retrieve container status"
}

# Deploy based on available tools
if [ "$USE_COMPOSE" = true ]; then
    deploy_with_compose
else
    deploy_with_podman
fi

echo ""
echo "=========================================="
echo "AEOS Deployment Complete!"
echo "=========================================="
echo ""
echo "Container Status:"
timeout 10 podman ps -a --filter "name=aeos-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "⚠️  Could not retrieve container status"
echo ""
echo "=========================================="
echo "Access AEOS at:"
echo "  HTTP:  http://localhost:8080/aeos"
echo "  HTTPS: https://localhost:8443/aeos"
echo ""
echo "To view logs:"
echo "  podman logs -f aeos-server"
echo "  podman logs -f aeos-lookup"
echo "  podman logs -f aeos-database"
echo ""
echo "To view all logs in real-time:"
echo "  podman logs -f aeos-database & podman logs -f aeos-lookup & podman logs -f aeos-server"
echo ""
echo "To check container status:"
echo "  podman ps -a --filter 'name=aeos-'"
echo ""
echo "To stop all containers:"
if [ "$USE_COMPOSE" = true ]; then
    echo "  podman-compose down"
else
    echo "  podman stop aeos-server aeos-lookup aeos-database"
fi
echo ""
echo "For more information, see README_CONTAINER.md"
echo "=========================================="
