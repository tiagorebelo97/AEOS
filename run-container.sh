#!/bin/bash
# Run script for AEOS container using Podman

set -e

CONTAINER_NAME="aeos"
IMAGE_TAG="latest"

echo "Starting AEOS container..."

# Run the container with Podman
# Modify the options below based on your application's needs

podman run -it \
    --name ${CONTAINER_NAME} \
    --rm \
    ${CONTAINER_NAME}:${IMAGE_TAG}

# Options explanation:
# -it: Interactive mode with terminal
# --name: Container name
# --rm: Remove container after exit
# Add more options as needed:
# -p 8080:8080: Port mapping
# -v ./data:/app/data: Volume mount
# -e VAR=value: Environment variable
