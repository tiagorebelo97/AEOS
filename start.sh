#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 Starting AEOS with Podman..."
echo ""

# Detect if we're using Docker or Podman
if command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
    COMPOSE_CMD="podman-compose"
    echo -e "${GREEN}✓${NC} Using Podman"
elif command -v docker &> /dev/null; then
    CONTAINER_CMD="docker"
    COMPOSE_CMD="docker-compose"
    echo -e "${GREEN}✓${NC} Using Docker"
else
    echo -e "${RED}✗${NC} Neither Docker nor Podman found. Please install one of them."
    exit 1
fi

echo "=========================================="
echo "AEOS Podman Deployment Script"
echo "=========================================="

# Check if container runtime is installed
if ! command -v ${CONTAINER_CMD} &> /dev/null; then
    echo -e "${RED}✗${NC} ${CONTAINER_CMD} is not installed"
    exit 1
fi
echo -e "${GREEN}✓${NC} ${CONTAINER_CMD} is installed"
${CONTAINER_CMD} version | head -1

# Check if compose is installed
if ! command -v ${COMPOSE_CMD} &> /dev/null; then
    echo -e "${RED}✗${NC} ${COMPOSE_CMD} is not installed"
    echo "Please install it with: pip install podman-compose"
    exit 1
fi
echo -e "${GREEN}✓${NC} ${COMPOSE_CMD} is installed"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file with secure random password..."
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    cat > .env << EOF
# AEOS Environment Configuration
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
EOF
    echo -e "${GREEN}✓${NC} Created .env file with secure password"
else
    echo -e "${GREEN}✓${NC} Using existing .env file"
fi

echo ""
echo "Building containers with ${COMPOSE_CMD}..."
${COMPOSE_CMD} build

echo ""
echo "Starting containers with ${COMPOSE_CMD}..."
${COMPOSE_CMD} up -d

echo ""
echo "=========================================="
echo -e "${GREEN}✓${NC} AEOS containers started successfully!"
echo "=========================================="
echo ""
echo "Container Status:"
${CONTAINER_CMD} ps --filter "name=aeos" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "📋 View logs:"
echo "  - All containers:     ${COMPOSE_CMD} logs -f"
echo "  - Database:           ${COMPOSE_CMD} logs -f aeos-database"
echo "  - Lookup Server:      ${COMPOSE_CMD} logs -f aeos-lookup"
echo "  - Application Server: ${COMPOSE_CMD} logs -f aeos-server"
echo ""
echo "  - Or with ${CONTAINER_CMD}:"
echo "    ${CONTAINER_CMD} logs -f aeos-database"
echo "    ${CONTAINER_CMD} logs -f aeos-lookup"
echo "    ${CONTAINER_CMD} logs -f aeos-server"
echo ""
echo "🔍 Check container health:"
echo "  ${COMPOSE_CMD} ps"
echo "  ${CONTAINER_CMD} inspect aeos-database --format '{{.State.Health.Status}}'"
echo "  ${CONTAINER_CMD} inspect aeos-lookup --format '{{.State.Health.Status}}'"
echo "  ${CONTAINER_CMD} inspect aeos-server --format '{{.State.Health.Status}}'"
echo ""
echo "🛑 Stop containers:"
echo "  ${COMPOSE_CMD} down"
echo ""
echo "🗑️  Remove all data (including database):"
echo "  ${COMPOSE_CMD} down -v"
echo ""
echo "Access AEOS:"
echo "  - Web Interface: http://localhost:8080"
echo "  - HTTPS:         https://localhost:8443"
echo "  - Server Port:   localhost:2506"
echo "  - Lookup Port:   localhost:2505"
echo ""
