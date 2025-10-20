#!/bin/bash
# Podman deployment script for AEOS
# This script helps deploy AEOS using Podman instead of Docker

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

# Check for .env file
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "⚠ Please edit .env and set secure passwords!"
    echo "Press Enter to continue after editing .env, or Ctrl+C to exit..."
    read
fi

# Function to deploy with podman-compose
deploy_with_compose() {
    echo ""
    echo "Building containers with podman-compose..."
    podman-compose build
    
    echo ""
    echo "Starting containers with podman-compose..."
    podman-compose up -d
    
    echo ""
    echo "Checking container status..."
    podman-compose ps
}

# Function to deploy with native podman
deploy_with_podman() {
    echo ""
    echo "Creating podman network..."
    podman network create aeos-network || echo "Network already exists"
    
    echo ""
    echo "Creating volumes..."
    podman volume create aeos-db-data || echo "Volume aeos-db-data already exists"
    podman volume create aeos-data || echo "Volume aeos-data already exists"
    podman volume create aeos-logs || echo "Volume aeos-logs already exists"
    
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
    podman ps -a --filter "name=aeos-"
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
echo "Access AEOS at:"
echo "  HTTP:  http://localhost:8080/aeos"
echo "  HTTPS: https://localhost:8443/aeos"
echo ""
echo "To view logs:"
echo "  podman logs -f aeos-server"
echo "  podman logs -f aeos-lookup"
echo "  podman logs -f aeos-database"
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
