# Building AEOS Containers

This document explains how the AEOS containers are built using the official AEOS installer.

## Overview

The AEOS containerization uses the official `aeosinstall_2023.1.8.sh` installer from the [GitHub releases](https://github.com/tiagorebelo97/AEOS/releases/tag/version0). This ensures that the containerized version contains the same binaries and components as the traditional AEOS installation.

## Build Process

### What Happens During Build

When you run `docker-compose build` or `podman build`, the following steps occur:

1. **Base Image**: Starts with `eclipse-temurin:11-jdk-jammy` (Java 11 on Ubuntu Jammy)

2. **Install Dependencies**: Installs required tools:
   - `wget` - To download the installer
   - `postgresql-client` - For database connectivity
   - `netcat-openbsd` - For network checks
   - `curl` - For health checks
   - `procps` - For process management

3. **Download AEOS Installer** (~1.4GB):
   ```bash
   wget https://github.com/tiagorebelo97/AEOS/releases/download/version0/aeosinstall_2023.1.8.sh
   ```

4. **Extract AEOS Installation**:
   - The installer is a self-extracting shell script
   - Contains a compressed tarball with all AEOS components
   - Runs silently with `-s` flag (no interactive prompts)
   - Installs to `/opt/aeos` directory

5. **Configure Container**:
   - Copies entrypoint and healthcheck scripts
   - Sets up proper permissions
   - Configures exposed ports

### What Gets Installed

The `aeosinstall_2023.1.8.sh` extracts the following components:

```
/opt/aeos/
├── AEserver/          # WildFly/JBoss application server
│   ├── bin/           # Server startup scripts
│   ├── standalone/    # Configuration and deployments
│   └── modules/       # Java modules
├── AEmon/             # AEOS monitoring application
│   └── doc/           # Documentation
├── bin/               # AEOS executables
│   ├── aemon          # Monitoring tool
│   ├── jini           # Lookup/service discovery
│   ├── config         # Configuration utility
│   └── applyconfig    # Apply configuration
├── lib/               # Java libraries
│   ├── aeos*.jar
│   ├── aepu*.jar
│   └── ...
├── utils/             # Utility tools
├── etc/               # Configuration files
└── ...
```

## Building the Containers

### Build All Services

```bash
# Using Docker
docker-compose build

# Using Podman
podman-compose build
```

### Build Individual Services

```bash
# AEOS Application Server
docker build -t aeos-server:2023.1.8 -f Dockerfile .

# AEOS Lookup Server
docker build -t aeos-lookup:2023.1.8 -f Dockerfile.lookup .
```

### Build Options

#### Using Build Cache

Docker/Podman will cache the downloaded installer. To force re-download:

```bash
docker-compose build --no-cache
```

#### Build with Progress

```bash
docker-compose build --progress=plain
```

#### Parallel Builds

```bash
docker-compose build --parallel
```

## Build Requirements

### Disk Space

- **During build**: ~10GB
  - Base images: ~500MB
  - AEOS installer download: ~1.4GB
  - Extracted AEOS: ~3GB
  - Intermediate layers: ~5GB
  
- **Final images**: ~4GB total
  - aeos-server: ~3GB
  - aeos-lookup: ~3GB (includes same AEOS installation)
  - postgres: ~200MB

### Memory

- **During build**: 4GB recommended
- **During runtime**: 8GB minimum (12GB recommended)

### Network

- Internet connection required to download installer
- Download speed affects build time (1.4GB file)

## Build Time

Typical build times (depending on hardware and network):

- **First build** (no cache): 10-20 minutes
  - Download installer: 2-10 minutes (depending on network)
  - Extract and configure: 5-10 minutes
  
- **Subsequent builds** (with cache): 1-2 minutes
  - Uses cached layers when possible

## Troubleshooting Build Issues

### Download Failures

If the installer download fails:

```bash
# Check GitHub releases are accessible
curl -I https://github.com/tiagorebelo97/AEOS/releases/download/version0/aeosinstall_2023.1.8.sh

# Retry build (Docker will resume download)
docker-compose build --no-cache
```

### Out of Disk Space

```bash
# Clean up unused Docker resources
docker system prune -a

# Or for Podman
podman system prune -a

# Check disk space
df -h
```

### Memory Issues

```bash
# Increase Docker memory limit (Docker Desktop)
# Go to Settings > Resources > Memory

# For Podman, increase system limits
ulimit -v unlimited
```

### Slow Builds

```bash
# Build one service at a time
docker-compose build aeos-database
docker-compose build aeos-lookup
docker-compose build aeos-server

# Use faster mirror (if available)
# Edit Dockerfile to use a mirror
```

## Verifying the Build

After building, verify the images:

```bash
# List images
docker images | grep aeos

# Check image size
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep aeos

# Inspect image
docker inspect aeos-server:latest

# Test run
docker run --rm aeos-server:latest /opt/aeos/AEserver/bin/standalone.sh --version
```

## Advanced Build Options

### Using Pre-Downloaded Installer

If you already have the installer downloaded:

1. Place `aeosinstall_2023.1.8.sh` in the repository root
2. Modify Dockerfile to `COPY` instead of `wget`:

```dockerfile
# Instead of wget, copy from local
COPY aeosinstall_2023.1.8.sh /tmp/aeosinstall.sh
```

### Building for Different Architectures

```bash
# Build for ARM64 (if supported)
docker buildx build --platform linux/arm64 -t aeos-server:arm64 .

# Multi-platform build
docker buildx build --platform linux/amd64,linux/arm64 -t aeos-server:multi .
```

### Custom Installation Directory

Modify the `AEOS_HOME` environment variable in Dockerfile:

```dockerfile
ENV AEOS_HOME=/custom/path/aeos
```

## Build Automation

### CI/CD Pipeline

Example GitHub Actions workflow:

```yaml
name: Build AEOS Containers

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build containers
        run: |
          docker-compose build
          docker-compose up -d
          docker-compose ps
```

### Pre-built Images

For faster deployment, pre-build and push to a registry:

```bash
# Build
docker-compose build

# Tag for registry
docker tag aeos-server:latest myregistry.com/aeos-server:2023.1.8
docker tag aeos-lookup:latest myregistry.com/aeos-lookup:2023.1.8

# Push
docker push myregistry.com/aeos-server:2023.1.8
docker push myregistry.com/aeos-lookup:2023.1.8
```

Then in your docker-compose.yml, use pre-built images:

```yaml
services:
  aeos-server:
    image: myregistry.com/aeos-server:2023.1.8
    # Remove 'build:' section
```

## Security Considerations

### Installer Integrity

The installer is downloaded from GitHub releases. Verify integrity:

```bash
# Download installer
wget https://github.com/tiagorebelo97/AEOS/releases/download/version0/aeosinstall_2023.1.8.sh

# Check SHA256 (from GitHub releases page)
sha256sum aeosinstall_2023.1.8.sh
# Expected: 21b398840b248177ec393680dba914bfea2350ef74522ddee472919fffe6c763
```

### Secure Build

- Build images on trusted systems
- Scan images for vulnerabilities
- Use minimal base images
- Keep base images updated

```bash
# Scan for vulnerabilities
docker scan aeos-server:latest

# Or with Trivy
trivy image aeos-server:latest
```

## Next Steps

After building the containers:

1. **Configure**: Edit `.env` file with your settings
2. **Deploy**: Run `docker-compose up -d`
3. **Verify**: Check logs with `docker-compose logs -f`
4. **Access**: Open http://localhost:8080/aeos

See [README_CONTAINER.md](README_CONTAINER.md) for deployment documentation.

## Support

For build issues:
- Check [Troubleshooting](#troubleshooting-build-issues) section
- Review build logs: `docker-compose build --progress=plain`
- Open an issue: https://github.com/tiagorebelo97/AEOS/issues

For AEOS software support:
- Contact Nedap Security Management
- See [aeos_technical_help_en_compressed.pdf](aeos_technical_help_en_compressed.pdf)
