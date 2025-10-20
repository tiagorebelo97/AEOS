#!/bin/bash
# Build script for AEOS container using Podman

set -e

CONTAINER_NAME="aeos"
IMAGE_TAG="latest"

echo "Building AEOS container image..."

# Build the container using Podman
podman build -t ${CONTAINER_NAME}:${IMAGE_TAG} -f Containerfile .

echo "Build complete!"
echo "Image: ${CONTAINER_NAME}:${IMAGE_TAG}"
echo ""
echo "To run the container, use: ./run-container.sh"
echo "Or with podman-compose: podman-compose -f podman-compose.yml up"
