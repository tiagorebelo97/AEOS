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

## Quick Start

### Using Docker

```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
cp .env.example .env
# Edit .env to set secure passwords
docker-compose up -d
```

Access AEOS at: http://localhost:8080/aeos

### Using Podman

```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
cp .env.example .env
# Edit .env to set secure passwords
./deploy-podman.sh
```

## Documentation

- **[Container Deployment Guide](README_CONTAINER.md)** - Complete containerization documentation
- **[Technical Help PDF](aeos_technical_help_en_compressed.pdf)** - Original AEOS documentation (1242 pages)

## Repository Structure

```
AEOS/
├── Dockerfile                          # Main AEOS application server
├── Dockerfile.lookup                   # AEOS lookup server
├── docker-compose.yml                  # Docker Compose configuration
├── podman-compose.yml                  # Podman Compose configuration
├── deploy-podman.sh                    # Podman deployment script
├── config/                             # Configuration templates
│   ├── aeos.properties.template        # Application properties
│   ├── server.xml                      # Tomcat configuration
│   └── ...
├── scripts/                            # Container entrypoint scripts
│   ├── entrypoint.sh                   # Application server startup
│   ├── healthcheck.sh                  # Health monitoring
│   └── ...
├── lookup-server/                      # Lookup server configuration
├── init-scripts/                       # Database initialization
│   └── 01-init-aeos-db.sql            # Schema creation
├── .env.example                        # Environment variables template
├── README_CONTAINER.md                 # Detailed container documentation
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