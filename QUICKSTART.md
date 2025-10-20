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
│  │    (Tomcat + Java)           │   │
│  │    Port: 8080, 8443, 2506    │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │ 📦 aeos-database container   │   │
│  │    (PostgreSQL)              │   │
│  │    Port: 5432                │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │ 📦 aeos-lookup container     │   │
│  │    (Java)                    │   │
│  │    Port: 2505                │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
         ✅ Fully containerized!
```

## Installation Methods

### Step 0: Obtain and Place AEOS Binaries (Required First!)

Before any installation method, you **must** obtain AEOS binaries from Nedap:

```bash
# 1. Contact Nedap Security Management to obtain AEOS software
# 2. Extract the binaries from the installation package
# 3. Place them in the correct directories:

cp /path/to/your/aeos.war binaries/app-server/
cp /path/to/your/aeos-lookup.jar binaries/lookup-server/

# 4. Verify binaries are in place:
ls -lh binaries/app-server/
ls -lh binaries/lookup-server/
```

📖 **See [binaries/README.md](binaries/README.md) for detailed binary placement instructions**

### Method 1: Docker Compose (Easiest)
```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
# Place binaries (see Step 0 above)
cp .env.example .env
# Edit .env to set passwords
docker-compose build
docker-compose up -d
```

### Method 2: Podman Deploy Script
```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
# Place binaries (see Step 0 above)
cp .env.example .env
# Edit .env to set passwords
./deploy-podman.sh
```

### Method 3: Podman Compose
```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
# Place binaries (see Step 0 above)
cp .env.example .env
# Edit .env to set passwords
podman-compose build
podman-compose up -d
```

### Method 4: Makefile
```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
# Place binaries (see Step 0 above)
make init-env  # Creates .env from template
# Edit .env to set passwords
make build     # Build images
make up        # For Docker
# OR
make build-podman
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
├── 📄 ANALYSIS_SUMMARY.md          # Technical analysis
├── 🐳 Dockerfile                   # App server image
├── 🐳 Dockerfile.lookup            # Lookup server image
├── 📋 docker-compose.yml           # Docker orchestration
├── 📋 podman-compose.yml           # Podman orchestration
├── 🔧 Makefile                     # Management commands
├── 🚀 deploy-podman.sh             # Podman deployment
├── 🧪 test-deployment.sh           # Testing script
├── 📚 aeos_technical_help_en_compressed.pdf  # Original docs
├── 📁 binaries/                    # ⭐ PLACE YOUR AEOS BINARIES HERE
│   ├── README.md                   # Binary placement guide
│   ├── app-server/                 # Put WAR files here
│   └── lookup-server/              # Put JAR files here
├── 📁 config/                      # Configuration templates
├── 📁 scripts/                     # Startup scripts
├── 📁 init-scripts/                # Database init
└── 📁 lookup-server/               # Lookup server config
```

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
3. ⭐ **Obtain AEOS binaries from Nedap** (CRITICAL!)
4. ⭐ **Place binaries in binaries/app-server/ and binaries/lookup-server/**
5. ✅ Create .env file with secure passwords
6. ✅ Build container images (this copies binaries into containers)
7. ✅ Run deployment command
8. ✅ Access web interface
9. 📖 Read README_CONTAINER.md for detailed info
10. 📖 Read binaries/README.md for binary placement help
11. 📖 Read ANALYSIS_SUMMARY.md for technical details
12. 📄 Review aeos_technical_help_en_compressed.pdf for AEOS features

## Support

- **Container Issues**: Open issue on GitHub
- **AEOS Software**: Contact Nedap Security Management
- **Documentation**: See README_CONTAINER.md

---

**🎉 AEOS is now containerized and ready to use with Podman!**
