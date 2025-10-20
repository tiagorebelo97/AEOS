# AEOS

A Linux-based application containerized for Podman.

## Container Support

This repository includes full support for running AEOS in a container using Podman (or Docker).

### Prerequisites

- **Podman** (recommended) or Docker installed on your system
  - Install Podman: `sudo apt install podman` (Ubuntu/Debian) or visit [podman.io](https://podman.io/)
- **podman-compose** (optional, for orchestration)
  - Install: `pip3 install podman-compose`

### Quick Start

#### Using Make (Recommended)

```bash
# Show available commands
make help

# Build the container
make build

# Run the container interactively
make run

# Run in detached mode
make run-detached

# View container logs
make logs

# Clean up (remove container and image)
make clean
```

#### Using Shell Scripts

1. **Build the container image:**
   ```bash
   ./build-container.sh
   ```

2. **Run the container:**
   ```bash
   ./run-container.sh
   ```

#### Using Podman directly

1. **Build the container image:**
   ```bash
   podman build -t aeos:latest -f Containerfile .
   ```

2. **Run the container:**
   ```bash
   podman run -it --rm --name aeos aeos:latest
   ```

#### Using podman-compose

1. **Build and run with compose:**
   ```bash
   podman-compose -f podman-compose.yml up
   ```

2. **Run in detached mode:**
   ```bash
   podman-compose -f podman-compose.yml up -d
   ```

3. **Stop the container:**
   ```bash
   podman-compose -f podman-compose.yml down
   ```

### Container Files

- **Containerfile** - Container build instructions (Podman/Docker compatible)
- **.containerignore** - Files to exclude from the container image
- **podman-compose.yml** - Container orchestration configuration
- **Makefile** - Convenient targets for building, running, and managing containers
- **build-container.sh** - Helper script to build the container
- **run-container.sh** - Helper script to run the container

### Customization

The container configuration can be customized by editing:

- **Containerfile**: Modify the base image, dependencies, or application setup
- **podman-compose.yml**: Configure ports, volumes, environment variables, and networks
- **Scripts**: Adjust build and run options in the shell scripts

### Common Commands

```bash
# List running containers
podman ps

# List all containers
podman ps -a

# List images
podman images

# Stop a running container
podman stop aeos

# Remove a container
podman rm aeos

# Remove an image
podman rmi aeos:latest

# View container logs
podman logs aeos

# Execute command in running container
podman exec -it aeos /bin/bash
```

### Rootless Podman

This container is designed to work with rootless Podman, which runs containers without requiring root privileges. This is a security best practice.

The container creates a non-root user `aeos` (UID 1000) for running the application.

## Development

For local development, you can mount your code directory into the container:

```bash
podman run -it --rm -v $(pwd):/app aeos:latest
```

## License

[Add your license here]