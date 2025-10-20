# AEOS Container Build Workflow

This document provides a visual overview of how the AEOS containerization works using the official installer.

## The Complete Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Repository                            │
│                  github.com/tiagorebelo97/AEOS                   │
│                                                                   │
│  Contains:                                                        │
│  • Dockerfiles (reference installer from releases)               │
│  • docker-compose.yml                                            │
│  • Configuration templates                                       │
│  • Entrypoint scripts                                            │
│  • Documentation                                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ git clone
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Your Machine / VM                             │
│                     /home/user/AEOS                              │
│                                                                   │
│  You run: docker-compose build                                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Build Process Starts
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Dockerfile Execution                           │
│                                                                   │
│  FROM eclipse-temurin:11-jdk-jammy                              │
│    ↓                                                             │
│  RUN apt-get install wget curl postgresql-client ...            │
│    ↓                                                             │
│  RUN wget https://github.com/.../aeosinstall_2023.1.8.sh        │
│    ↓                                                             │
│  RUN /tmp/aeosinstall.sh -s -d /opt/aeos                        │
│    ↓                                                             │
│  COPY scripts/entrypoint.sh /usr/local/bin/                     │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Downloads from GitHub Releases
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Releases                              │
│         github.com/tiagorebelo97/AEOS/releases/version0         │
│                                                                   │
│  Assets:                                                         │
│  • aeosinstall_2023.1.8.sh (1.4 GB)  ← Downloads this           │
│  • aepuinstall_2023.1.8.sh                                      │
│  • aeos_technical_help_en.pdf                                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Installer extracts
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              Inside Container: /opt/aeos/                        │
│                                                                   │
│  AEserver/          ← WildFly application server                │
│  ├── bin/                                                        │
│  ├── standalone/                                                 │
│  └── modules/                                                    │
│  AEmon/             ← Monitoring application                     │
│  bin/               ← AEOS executables (jini, config, etc.)     │
│  lib/               ← Java libraries                             │
│  utils/             ← Utility tools                              │
│  etc/               ← Configuration files                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Build completes
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Container Images                              │
│                                                                   │
│  ✓ aeos-server:latest    (~3 GB)                                │
│  ✓ aeos-lookup:latest    (~3 GB)                                │
│  ✓ postgres:14-alpine    (~200 MB)                              │
│                                                                   │
│  Images contain REAL AEOS binaries!                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ docker-compose up -d
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Running Containers                              │
│                                                                   │
│  ┌─────────────────────────────────────────┐                    │
│  │  aeos-database (PostgreSQL)             │                    │
│  │  • Port: 5432                           │                    │
│  │  • Volume: aeos-db-data                 │                    │
│  └─────────────────────────────────────────┘                    │
│               ▲                                                  │
│               │ Database connection                              │
│  ┌────────────┴────────────────────────────┐                    │
│  │  aeos-lookup (Jini Service)             │                    │
│  │  • Port: 2505                           │                    │
│  │  • Runs: /opt/aeos/bin/jini             │                    │
│  └─────────────────────────────────────────┘                    │
│               ▲                                                  │
│               │ Lookup service                                   │
│  ┌────────────┴────────────────────────────┐                    │
│  │  aeos-server (WildFly)                  │                    │
│  │  • Port: 8080, 8443, 2506               │                    │
│  │  • Runs: /opt/aeos/AEserver/bin/        │                    │
│  │          standalone.sh                  │                    │
│  │  • Volume: aeos-data, aeos-logs         │                    │
│  └─────────────────────────────────────────┘                    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Access via browser
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     User's Browser                               │
│                                                                   │
│  http://localhost:8080/aeos                                     │
│    or                                                            │
│  http://vm-ip:8080/aeos                                         │
│                                                                   │
│  ✓ Full AEOS web interface                                      │
│  ✓ Same as traditional installation                             │
│  ✓ But running in containers!                                   │
└─────────────────────────────────────────────────────────────────┘
```

## What Makes This Special

### Traditional AEOS Installation

```
Windows Server
    ↓
Download installer manually
    ↓
Run installer GUI
    ↓
Configure manually
    ↓
Start services manually
    ↓
Complex, platform-specific
```

### Containerized AEOS Installation

```
Any OS with Docker/Podman
    ↓
git clone && docker-compose build
    ↓
Automatic download & install
    ↓
Automatic configuration
    ↓
docker-compose up -d
    ↓
Simple, portable, reproducible
```

## Key Benefits

| Aspect | Traditional | Containerized |
|--------|------------|---------------|
| **Platform** | Windows Server only | Linux, Windows, macOS |
| **Install Time** | 1-2 hours | 10-20 minutes |
| **Install Method** | Manual GUI | Automated script |
| **Reproducibility** | Difficult | Perfect |
| **Scaling** | Manual | Docker Swarm/K8s |
| **Updates** | Complex | docker-compose build |
| **Backup** | Complex | Volume snapshots |
| **Rollback** | Difficult | Image tags |
| **Testing** | Risky | Isolated containers |
| **Cost** | Windows licenses | No Windows needed |

## Technical Details

### Installer Structure

The `aeosinstall_2023.1.8.sh` is a self-extracting archive:

```
aeosinstall_2023.1.8.sh
├── Shell script header (269 lines)
│   ├── License agreement
│   ├── Installation logic
│   ├── Configuration scripts
│   └── Backup/restore functions
│
└── Embedded tarball (at line 271)
    └── aeos.tar.gz (compressed)
        ├── AEserver/ (WildFly server)
        ├── AEmon/ (Monitoring)
        ├── bin/ (Executables)
        ├── lib/ (Java libraries)
        └── utils/ (Tools)
```

### Build Command Flow

When you run `docker-compose build`:

```bash
docker-compose build
  ↓
Reads docker-compose.yml
  ↓
For each service with 'build:' section:
  ↓
  Reads Dockerfile
  ↓
  Executes each instruction (FROM, RUN, COPY, etc.)
  ↓
  RUN wget ... downloads installer (1.4 GB)
  ↓
  RUN ./aeosinstall.sh -s -d /opt/aeos
    ↓
    Extracts tarball
    ↓
    Configures Java paths
    ↓
    Sets up WildFly
    ↓
    Creates configuration files
  ↓
  Saves as Docker image layer
  ↓
Creates final image: aeos-server:latest
```

### Runtime Command Flow

When you run `docker-compose up -d`:

```bash
docker-compose up -d
  ↓
Reads docker-compose.yml
  ↓
Creates network: aeos-network
  ↓
Creates volumes: aeos-db-data, aeos-data, aeos-logs
  ↓
Starts containers in dependency order:
  ↓
  1. aeos-database (PostgreSQL)
     ENTRYPOINT: docker-entrypoint.sh postgres
     ↓
     Initializes database
     ↓
     Creates aeos database and user
     ↓
     Health check: pg_isready
  ↓
  2. aeos-lookup (waits for database)
     ENTRYPOINT: /usr/local/bin/lookup-entrypoint.sh
     ↓
     Waits for database (nc -z)
     ↓
     Starts Jini service
     ↓
     Listens on port 2505
  ↓
  3. aeos-server (waits for database & lookup)
     ENTRYPOINT: /usr/local/bin/entrypoint.sh run
     ↓
     Waits for database (nc -z)
     ↓
     Waits for lookup (nc -z)
     ↓
     Configures database connection
     ↓
     Starts WildFly
     ↓
     Deploys AEOS web application
     ↓
     Listens on ports 8080, 8443, 2506
```

## File Changes Made

The following files were modified to support the official installer:

### Modified Files

1. **Dockerfile**
   - Changed base image from Tomcat to `eclipse-temurin:11-jdk-jammy`
   - Added wget download of installer from GitHub releases
   - Added silent installation: `/tmp/aeosinstall.sh -s -d /opt/aeos`
   - Updated ports and paths for WildFly

2. **Dockerfile.lookup**
   - Same changes as Dockerfile (uses same AEOS installation)
   - Different entrypoint to run Jini service

3. **scripts/entrypoint.sh**
   - Updated to start WildFly instead of Tomcat
   - Added database connection configuration
   - Runs: `${AEOS_HOME}/AEserver/bin/standalone.sh`

4. **scripts/lookup-entrypoint.sh**
   - Updated to run Jini service from AEOS installation
   - Runs: `${AEOS_HOME}/bin/jini`

5. **scripts/healthcheck.sh**
   - Updated to check WildFly management port (9990)
   - Checks HTTP port (8080)

### New Files

1. **BUILD.md**
   - Comprehensive guide to the build process
   - Explains what happens during build
   - Troubleshooting and optimization tips

2. **VM_DEPLOYMENT.md**
   - Step-by-step guide for VM deployment
   - Network and firewall configuration
   - Auto-start and maintenance procedures

### Updated Files

1. **README.md**
   - Added section explaining the build process
   - Updated quick start with build step
   - Added links to new documentation

2. **README_CONTAINER.md**
   - Updated prerequisites (disk space, build time)
   - Added build process section
   - Updated quick start guide

3. **QUICKSTART.md**
   - Added build time warnings
   - Updated file structure
   - Added build command to all methods

## Security Verification

The installer is verified by:

1. **Source**: Official GitHub release from tiagorebelo97/AEOS
2. **SHA256**: `21b398840b248177ec393680dba914bfea2350ef74522ddee472919fffe6c763`
3. **Download**: Uses HTTPS from GitHub
4. **Signature**: GitHub release assets (signed by uploader)

To verify manually:
```bash
wget https://github.com/tiagorebelo97/AEOS/releases/download/version0/aeosinstall_2023.1.8.sh
sha256sum aeosinstall_2023.1.8.sh
```

## Support and Next Steps

### For Building
- See [BUILD.md](BUILD.md) for detailed build information
- See [VM_DEPLOYMENT.md](VM_DEPLOYMENT.md) for VM-specific deployment
- See [README_CONTAINER.md](README_CONTAINER.md) for full documentation

### For Running
- See [QUICKSTART.md](QUICKSTART.md) for quick start
- See [docker-compose.yml](docker-compose.yml) for service configuration
- See [.env.example](.env.example) for configuration options

### For Issues
- Container build/runtime issues: Open GitHub issue
- AEOS functionality: Contact Nedap Security Management
- Documentation: See [aeos_technical_help_en_compressed.pdf](aeos_technical_help_en_compressed.pdf)

---

**Summary**: The containerization now uses the REAL AEOS binaries from the official installer, making it production-ready and fully compatible with traditional AEOS installations.
