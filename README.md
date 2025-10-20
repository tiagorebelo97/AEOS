# AEOS - Containerized Access Control System

[![Docker](https://img.shields.io/badge/Docker-Compatible-blue.svg)](https://www.docker.com/)
[![Podman](https://img.shields.io/badge/Podman-Compatible-purple.svg)](https://podman.io/)

## Overview

This repository provides a **containerized deployment** of the AEOS (Access Control and Security Management System) by Nedap Security Management. AEOS is an enterprise-level physical access control system that manages door access, security badges, and building security.

### What's New: Container Support

The AEOS system traditionally required Windows Server installation. This repository now provides:

✅ **Docker/Podman container support** - Run AEOS in containers  
✅ **Multi-container architecture** - Separate database, lookup server, and application server  
✅ **Easy deployment** - Simple setup with docker-compose or podman-compose  
✅ **Cloud-ready** - Deploy on any container platform  
✅ **Scalable** - Container orchestration support  
✅ **Official AEOS binaries** - Uses the official aeosinstall_2023.1.8.sh from GitHub releases

### How It Works

The containerized AEOS system automatically downloads and installs the official AEOS 2023.1.8 installer during the Docker/Podman build process. The installer (`aeosinstall_2023.1.8.sh`) is a self-extracting archive containing:

- **AEserver** - WildFly/JBoss application server with AEOS web application
- **AEmon** - AEOS monitoring and management tools
- **Jini/Lookup Server** - Service discovery and communication coordinator
- **Libraries and utilities** - All required Java libraries and tools

The build process:
1. Downloads `aeosinstall_2023.1.8.sh` from GitHub releases (1.4GB)
2. Extracts the AEOS installation non-interactively
3. Configures the system for containerized deployment
4. Sets up proper database connections and networking  

## Quick Start

### Prerequisites

- Docker 20.10+ or Podman 3.0+
- Docker Compose or Podman Compose
- 8GB RAM minimum (12GB recommended for building)
- 50GB disk space (build requires ~10GB, running requires ~20GB)
- Internet connection (to download the 1.4GB AEOS installer)

### Simplest Method (Auto-detects Docker/Podman)

```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
./start.sh  # That's it!
```

The `start.sh` script automatically:
- Detects whether you have Docker or Podman
- Creates secure random passwords
- Builds all container images
- Starts all services

**No manual configuration needed!**

### Using Docker

```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
cp .env.example .env
# Edit .env to set secure passwords
docker-compose build  # Downloads and installs AEOS (this takes time!)
docker-compose up -d
```

Access AEOS at: http://localhost:8080/aeos

### Using Podman

```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
./deploy-podman.sh  # Automatically sets up and starts everything!
```

That's it! The script automatically:
- Creates a secure `.env` file with random password
- Builds all container images
- Starts all services

No manual configuration needed!

## Documentation

- **[Quick Start Guide](QUICKSTART.md)** - Fast track to get AEOS running
- **[VM Deployment Guide](VM_DEPLOYMENT.md)** - Deploy on a Virtual Machine
- **[Container Deployment Guide](README_CONTAINER.md)** - Complete containerization documentation
- **[Build Process Guide](BUILD.md)** - Understanding the build process
- **[Technical Help PDF](aeos_technical_help_en_compressed.pdf)** - Original AEOS documentation (1242 pages)

## Repository Structure

```
AEOS/
├── start.sh                             # Universal launcher (auto-detects Docker/Podman)
├── deploy-podman.sh                     # Automated Podman deployment script
├── Dockerfile                           # Main AEOS application server
├── Dockerfile.lookup                    # AEOS lookup server
├── docker-compose.yml                   # Docker Compose configuration
├── podman-compose.yml                   # Podman Compose configuration
├── config/                              # Configuration templates
│   ├── aeos.properties.template         # Application properties
│   ├── server.xml                       # Tomcat configuration
│   └── ...
├── scripts/                             # Container entrypoint scripts
│   ├── entrypoint.sh                    # Application server startup
│   ├── healthcheck.sh                   # Health monitoring
│   └── ...
├── lookup-server/                       # Lookup server configuration
├── init-scripts/                        # Database initialization
│   └── 01-init-aeos-db.sql             # Schema creation
├── .env.example                         # Environment variables template
├── README_CONTAINER.md                  # Detailed container documentation
└── aeos_technical_help_en_compressed.pdf  # Original documentation

```

## System Components

The containerized AEOS system includes:

1. **PostgreSQL Database** - Stores all system data
2. **AEOS Lookup Server** - Handles network communication
3. **AEOS Application Server** - Web interface and core logic

## Requirements

- Docker 20.10+ or Podman 3.0+
- Docker Compose or Podman Compose
- 8GB RAM minimum
- 50GB disk space

## Features

- 🔐 **Access Control Management** - Control who can access which doors
- 👥 **Carrier Management** - Manage people and vehicles with access rights
- 🚪 **Door Controller Integration** - Connect to physical hardware (AEpus)
- 📊 **Event Logging** - Track all access events
- 🔄 **Multi-site Support** - Manage multiple locations
- 🌐 **Web Interface** - Browser-based administration

## Network Ports

| Port | Service | Purpose |
|------|---------|---------|
| 8080 | HTTP | Web interface |
| 8443 | HTTPS | Secure web interface |
| 2505 | TCP | Lookup server |
| 2506 | TCP | Application server |
| 5432 | TCP | PostgreSQL database |

## License

⚠️ **Important**: AEOS is proprietary software requiring a license from Nedap Security Management. This repository provides the containerization infrastructure only.

Contact: https://www.nedapsecurity.com/

## Support

- **Container Issues**: [Open an issue](https://github.com/tiagorebelo97/AEOS/issues)
- **AEOS Documentation**: See `aeos_technical_help_en_compressed.pdf`
- **Nedap Support**: https://www.nedapsecurity.com/support

## Contributing

Contributions are welcome! Please submit pull requests or open issues for improvements.

---

**Note**: This is a community-driven containerization project. For official AEOS support and licensing, contact Nedap Security Management.