# Container Usage Guide for AEOS

This guide provides detailed information on using the AEOS container with Podman.

## What Has Been Set Up

The AEOS repository now includes complete containerization support with:

1. **Containerfile** - A Podman-native container definition (also compatible with Docker)
2. **Build and Run Scripts** - Simple shell scripts for quick container operations
3. **Makefile** - Professional-grade build automation
4. **Compose Configuration** - podman-compose.yml for multi-container scenarios
5. **Comprehensive Documentation** - Updated README with usage examples

## Container Features

### Security
- **Non-root user**: The container runs as user `aeos` (UID 1000), not as root
- **Minimal base image**: Uses Ubuntu 22.04 LTS for security and stability
- **Clean dependency management**: Only necessary packages are installed
- **Rootless Podman compatible**: Works with rootless Podman for enhanced security

### Flexibility
- **Multiple usage methods**: Makefile, scripts, direct Podman commands, or compose
- **Customizable**: Easy to modify for specific application needs
- **Documentation**: Inline comments and comprehensive README

### Best Practices
- Uses `.containerignore` to exclude unnecessary files
- Includes `.gitignore` for repository cleanliness
- Follows Podman/Docker best practices for layer optimization
- Environment variables for non-interactive builds

## Quick Reference

### Basic Operations

```bash
# Build
make build

# Run interactively
make run

# Run in background
make run-detached

# View logs
make logs

# Stop container
make stop

# Clean up everything
make clean
```

### Advanced Usage

#### Custom Port Mapping
```bash
podman run -it --rm -p 8080:8080 aeos:latest
```

#### Volume Mount
```bash
podman run -it --rm -v /host/path:/app/data aeos:latest
```

#### Environment Variables
```bash
podman run -it --rm -e MY_VAR=value aeos:latest
```

#### Custom Command
```bash
podman run -it --rm aeos:latest /bin/bash -c "your-command"
```

## Customizing for Your Application

### Adding Dependencies

Edit the `Containerfile` and add packages in the RUN instruction:

```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    your-package-here \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

### Exposing Ports

Uncomment and modify the EXPOSE instruction in `Containerfile`:

```dockerfile
EXPOSE 8080
```

And update `podman-compose.yml`:

```yaml
ports:
  - "8080:8080"
```

### Adding Application Files

Uncomment the COPY instruction in `Containerfile`:

```dockerfile
COPY . /app/
```

### Changing the Startup Command

Modify the CMD instruction in `Containerfile`:

```dockerfile
CMD ["your-application", "--args"]
```

## Troubleshooting

### Build Issues

If you encounter permission errors during build:
```bash
podman build --cgroup-manager=cgroupfs -t aeos:latest -f Containerfile .
```

### Runtime Issues

Check container logs:
```bash
podman logs aeos
```

Enter running container for debugging:
```bash
podman exec -it aeos /bin/bash
```

### Cleanup

Remove all AEOS containers and images:
```bash
make clean
```

Or manually:
```bash
podman stop aeos
podman rm aeos
podman rmi aeos:latest
```

## Migration from Docker

All commands work with Docker by replacing `podman` with `docker`:

```bash
# Docker commands
docker build -t aeos:latest -f Containerfile .
docker run -it --rm aeos:latest
docker-compose -f podman-compose.yml up
```

The Containerfile is fully compatible with Docker's `docker build` command.

## Next Steps

1. **Add your application code** to the repository
2. **Modify the Containerfile** to install your application's dependencies
3. **Update the CMD** instruction to start your application
4. **Test the container** with `make build && make run`
5. **Customize ports, volumes, and environment** as needed

## Support

For Podman documentation: https://podman.io/
For container best practices: https://docs.docker.com/develop/dev-best-practices/
