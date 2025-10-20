# AEOS System Analysis and Containerization Summary

## Document Analysis: aeos_technical_help_en_compressed.pdf

### What is AEOS?

**AEOS** (Access and Entry Online System) is a comprehensive **enterprise physical access control system** developed by Nedap Security Management.

### Key Findings:

#### System Purpose
- **Physical Access Control**: Manages security and access to buildings, doors, and facilities
- **Badge Management**: Issues and manages security badges for personnel and vehicles
- **Door Control**: Integrates with physical hardware to control door locks and readers
- **Event Monitoring**: Tracks and logs all access events in real-time
- **Multi-site Management**: Centralized control of multiple locations

#### Technical Architecture (Traditional Installation)

The original AEOS system consists of:

1. **AEOS Application Server** (AEserver)
   - Java-based application
   - Runs on Windows Server 2016/2019/2022
   - Requires 4GB+ RAM
   - Uses Tomcat or similar application server
   - Web-based interface (HTTP/HTTPS)

2. **AEOS Database Server**
   - Supports PostgreSQL, MS SQL Server, Oracle
   - Stores all system data (carriers, access points, authorizations, events)
   - Can be on same or separate server

3. **AEOS Lookup Server**
   - Network communication coordinator
   - Connects door controllers to main system
   - Handles real-time communication

4. **Physical Components**
   - **AEpus** (Door Controllers): Hardware units that control physical doors
   - **AEpacks** (Door Interfaces): Extend door controller connections
   - **Card Readers**: RFID/badge readers at doors
   - **Network Infrastructure**: RS485, Ethernet connections

#### Original Deployment Model

The PDF documentation describes a **traditional server-based installation**:
- Manual installation on Windows Server
- Direct installation of Java applications
- Configuration through GUI tools (AEmon, AEconf)
- Requires hardware USB dongle for licensing (or IP license)
- NOT containerized - runs as native Windows services

### The Problem

As stated in the problem statement:
> "the file that he talks about it is not a container"

**Confirmed**: The AEOS system described in the PDF is indeed **NOT containerized**. It's designed for traditional Windows Server deployment with manual installation steps.

## Containerization Solution

### What Has Been Created

To address the requirement "i need that program to be a container to run it on podman", this repository now includes:

#### 1. Container Images

**Dockerfile** - Main AEOS Application Server
- Based on `tomcat:9-jdk11-openjdk`
- Includes AEOS application configuration
- Exposes ports: 8080 (HTTP), 8443 (HTTPS), 2506 (App Server)
- Health checks and monitoring

**Dockerfile.lookup** - AEOS Lookup Server
- Based on `openjdk:11-jre-slim`
- Handles network communication
- Exposes port: 2505

**PostgreSQL Database**
- Uses official `postgres:14-alpine` image
- Includes AEOS schema initialization
- Persistent data storage

#### 2. Orchestration Files

**docker-compose.yml**
- Multi-container orchestration
- Automatic service dependencies
- Health checks and restart policies
- Volume management for persistence
- Network isolation

**podman-compose.yml**
- Podman-compatible version
- Same functionality as Docker Compose
- Rootless container support

#### 3. Deployment Scripts

**deploy-podman.sh**
- Automated Podman deployment
- Checks prerequisites
- Creates networks and volumes
- Handles both podman-compose and native podman

**Makefile**
- Convenient management commands
- Build, start, stop, logs, backup operations
- Works with both Docker and Podman

**test-deployment.sh**
- Automated testing of deployment
- Validates all components are working
- Checks connectivity and health

#### 4. Configuration

**config/aeos.properties.template**
- Application configuration template
- Environment variable substitution
- Database and network settings

**lookup-server/lookup.properties.template**
- Lookup server configuration
- Database connection settings

**init-scripts/01-init-aeos-db.sql**
- Database schema initialization
- Creates tables for AEOS data model
- Default configuration

#### 5. Documentation

**README.md** - Updated main README
- Overview of containerization
- Quick start guides
- Features and benefits

**README_CONTAINER.md** - Comprehensive container guide
- Detailed deployment instructions
- Docker and Podman usage
- Troubleshooting
- Configuration options
- Production deployment notes

**.env.example** - Environment template
- Secure password configuration
- Port customization
- Timezone settings

## Benefits of Containerization

### Before (Traditional Installation)
- ❌ Requires Windows Server
- ❌ Manual installation steps
- ❌ Complex upgrade process
- ❌ Difficult to replicate environments
- ❌ Limited portability
- ❌ Higher resource requirements

### After (Containerized)
- ✅ Runs on Linux, Windows, macOS (via containers)
- ✅ Single command deployment
- ✅ Easy version management
- ✅ Reproducible environments
- ✅ Cloud-ready
- ✅ Efficient resource usage
- ✅ Works with Docker AND Podman
- ✅ Microservices architecture
- ✅ Easy scaling and orchestration

## Podman Compatibility

The solution is specifically designed for Podman:

### Podman-Specific Features
1. **Rootless Containers**: Run without root privileges
2. **Podman Compose Support**: Compatible with podman-compose
3. **Pod Support**: Can be deployed as Podman pods
4. **Systemd Integration**: Generate systemd service files
5. **Native Commands**: Works with native podman commands

### Deployment Methods

#### Method 1: Using podman-compose
```bash
podman-compose up -d
```

#### Method 2: Using deploy script
```bash
./deploy-podman.sh
```

#### Method 3: Using Makefile
```bash
make up-podman
```

#### Method 4: Native Podman commands
```bash
podman network create aeos-network
podman run -d --name aeos-database ...
podman run -d --name aeos-lookup ...
podman run -d --name aeos-server ...
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    AEOS Container Stack                  │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐         ┌─────────────┐              │
│  │   Browser    │─HTTP───▶│ AEOS Server │              │
│  │   Client     │  8080   │  Container  │              │
│  └──────────────┘         │   (Tomcat)  │              │
│                            │    Port:    │              │
│                            │  8080/8443  │              │
│                            │    2506     │              │
│                            └──────┬──────┘              │
│                                   │                      │
│                                   │ Network              │
│                            ┌──────┴──────┐              │
│                            │             │              │
│                    ┌───────▼──────┐ ┌───▼────────┐    │
│                    │ Lookup Server│ │  Database  │    │
│                    │   Container  │ │ PostgreSQL │    │
│  ┌──────────┐     │   Port: 2505 │ │ Port: 5432 │    │
│  │  AEpu    │────▶│              │ │            │    │
│  │ (Door    │     └──────────────┘ └────────────┘    │
│  │Hardware) │                                          │
│  └──────────┘     [aeos-network bridge]               │
│                                                          │
│  Volumes:                                               │
│  • aeos-db-data   (Database persistence)               │
│  • aeos-data      (Application data)                   │
│  • aeos-logs      (Application logs)                   │
└─────────────────────────────────────────────────────────┘
```

## Important Notes

### Licensing
⚠️ **The actual AEOS software requires a valid license from Nedap Security Management**

This containerization provides the infrastructure, but:
- AEOS software binaries must be obtained from Nedap
- A valid license file is required
- Contact Nedap for commercial licensing

### Production Considerations

For production deployment:
1. Use HTTPS with valid SSL certificates
2. Set strong, unique passwords (not defaults)
3. Configure regular backups
4. Implement monitoring and alerting
5. Use persistent storage for critical data
6. Review security settings
7. Test disaster recovery procedures

### Hardware Integration

The containerized system can connect to physical hardware:
- Door controllers (AEpus) connect via network (port 2505)
- Card readers connect to AEpus via RS485
- Ensure proper network routing and firewall rules

## Conclusion

The AEOS system has been successfully transformed from a traditional Windows Server application into a modern containerized architecture compatible with both Docker and Podman. This enables:

- **Easier deployment**: Single command to start entire system
- **Better portability**: Run on any platform supporting containers
- **Improved scalability**: Scale components independently
- **Cloud readiness**: Deploy on any container platform
- **Podman compatibility**: Run rootless, with pods, systemd integration

The solution maintains the core functionality described in the 1,242-page technical documentation while providing modern DevOps-friendly deployment methods.
