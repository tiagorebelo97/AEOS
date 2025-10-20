#!/bin/bash
# Simple launcher for AEOS with Podman
# This is the simplest way to get AEOS running
# Usage: ./start.sh

set -e

echo "🚀 Starting AEOS with Podman..."
echo ""

# Detect if we should use Docker or Podman
if command -v podman &> /dev/null; then
    echo "✓ Using Podman"
    ./deploy-podman.sh
elif command -v docker &> /dev/null; then
    echo "✓ Using Docker"
    
    # Create .env if it doesn't exist
    if [ ! -f .env ]; then
        echo "Creating .env file..."
        if command -v openssl &> /dev/null; then
            DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        else
            DB_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 25 | head -n 1)
        fi
        cat > .env << EOF
# Environment Variables for AEOS Container Setup
# Auto-generated on $(date)

# Database Configuration
AEOS_DB_PASSWORD=${DB_PASSWORD}

# Timezone Configuration
TZ=UTC
EOF
        echo "✓ Created .env file"
    fi
    
    echo "Building and starting containers..."
    docker-compose build
    docker-compose up -d
    
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
    echo "  docker-compose logs -f"
    echo ""
    echo "To stop:"
    echo "  docker-compose down"
    echo ""
    echo "For troubleshooting and next steps, see POST_BUILD.md"
    echo "=========================================="
else
    echo "❌ Error: Neither Podman nor Docker is installed"
    echo ""
    echo "Please install one of:"
    echo "  - Podman: https://podman.io/getting-started/installation"
    echo "  - Docker: https://docs.docker.com/get-docker/"
    exit 1
fi
