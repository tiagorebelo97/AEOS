# AEOS Quick Start Guide

## What You Need to Know

### Original AEOS (Before)
```
┌─────────────────────────────────────┐
│      Windows Server 2016/2019       │
│  ┌──────────────────────────────┐   │
│  │   AEOS Application Server    │   │
│  │     (Manual Installation)    │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │        SQL Database          │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │      AEOS Lookup Server      │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
         ❌ NOT containerized
```

### Containerized AEOS (Now)
```
┌─────────────────────────────────────┐
│         Docker/Podman Host          │
│  ┌──────────────────────────────┐   │
│  │ 📦 aeos-server container     │   │
│  │    (WildFly + Real AEOS)     │   │
│  │    Port: 8080, 8443, 2506    │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │ 📦 aeos-database container   │   │
│  │    (PostgreSQL)              │   │
│  │    Port: 5432                │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │ 📦 aeos-lookup container     │   │
│  │    (Jini Service)            │   │
│  │    Port: 2505                │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
         ✅ Fully containerized!
    Uses official AEOS 2023.1.8 binaries
```

## Installation Methods

**⚠️ Note**: First build takes 10-20 minutes to download and install the 1.4GB AEOS installer. Subsequent builds are much faster (~1-2 minutes).

### Method 1: Universal Start Script (Simplest!)
```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
./start.sh  # Auto-detects Docker or Podman and does everything!
```
**✨ The easiest way!** Auto-detects your container runtime, creates secure passwords, builds images, and starts all services.

### Method 2: Podman Deploy Script
```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
./deploy-podman.sh  # Does everything automatically!
```
**✨ Fully automatic!** Creates secure passwords, builds images, and starts all services.

### Method 3: Docker Compose
```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
cp .env.example .env
# Edit .env to set passwords
docker-compose build  # Downloads AEOS installer (takes time!)
docker-compose up -d
```

### Method 4: Podman Compose
```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
cp .env.example .env
# Edit .env to set passwords
podman-compose build  # Downloads AEOS installer (takes time!)
podman-compose up -d
```

### Method 5: Makefile
```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
make init-env  # Creates .env from template
# Edit .env to set passwords
make build     # Builds containers (takes time!)
make up        # For Docker
# OR
make up-podman # For Podman
```

## Accessing AEOS

After deployment:

1. **Web Interface**: http://localhost:8080/aeos
2. **Secure Web**: https://localhost:8443/aeos
3. **Database**: localhost:5432 (user: aeos, db: aeos)

## Common Commands

### Docker
```bash
docker-compose ps              # Check status
docker-compose logs -f         # View logs
docker-compose restart         # Restart all
docker-compose down            # Stop all
```

### Podman
```bash
podman ps -a                   # Check status
podman logs -f aeos-server     # View logs
podman restart aeos-server     # Restart service
podman stop aeos-server        # Stop service
```

### Makefile
```bash
make status        # Check status
make logs          # View logs
make restart       # Restart
make down          # Stop all
make backup-db     # Backup database
make test          # Run tests
```

## File Structure

```
AEOS/
├── 📄 README.md                    # Main documentation
├── 📄 README_CONTAINER.md          # Detailed container guide
├── 📄 BUILD.md                     # Build process documentation
├── 📄 QUICKSTART.md                # This quick start guide
├── 📄 ANALYSIS_SUMMARY.md          # Technical analysis
├── 🚀 start.sh                     # Universal launcher (simplest!)
├── 🚀 deploy-podman.sh             # Automated Podman deployment
├── 🐳 Dockerfile                   # App server image (uses official installer)
├── 🐳 Dockerfile.lookup            # Lookup server image (uses official installer)
├── 📋 docker-compose.yml           # Docker orchestration
├── 📋 podman-compose.yml           # Podman orchestration
├── 🔧 Makefile                     # Management commands
├── 🧪 test-deployment.sh           # Testing script
├── 📚 aeos_technical_help_en_compressed.pdf  # Original docs
├── 📁 config/                      # Configuration templates
├── 📁 scripts/                     # Startup scripts
├── 📁 init-scripts/                # Database init
└── 📁 lookup-server/               # Lookup server config
```

**GitHub Release**: https://github.com/tiagorebelo97/AEOS/releases/tag/version0
- Contains `aeosinstall_2023.1.8.sh` (1.4GB) - Official AEOS installer
- Automatically downloaded during container build

## Troubleshooting

### Containers won't start?
```bash
# Check logs
docker-compose logs
# or
podman logs aeos-server

# Check if ports are in use
netstat -tuln | grep -E '8080|5432|2505'
```

### Can't access web interface?
```bash
# Check if container is running
docker-compose ps
# or
podman ps

# Check firewall
sudo ufw status
sudo ufw allow 8080/tcp
```

### Database connection failed?
```bash
# Check database health
docker exec aeos-database pg_isready -U aeos
# or
podman exec aeos-database pg_isready -U aeos
```

## Next Steps

1. ✅ Install Docker or Podman
2. ✅ Clone the repository
3. ✅ Create .env file with secure passwords
4. ✅ Run build command (be patient, downloads 1.4GB installer)
5. ✅ Run deployment command
6. ✅ Access web interface
7. 📖 Read README_CONTAINER.md for detailed info
8. 📖 Read BUILD.md for build process details
9. 📖 Read ANALYSIS_SUMMARY.md for technical details
10. 📄 Review aeos_technical_help_en_compressed.pdf for AEOS features

## Support

- **Container Issues**: Open issue on GitHub
- **AEOS Software**: Contact Nedap Security Management
- **Documentation**: See README_CONTAINER.md

---

**🎉 AEOS is now containerized and ready to use with Podman!**
