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

### Method 1: Docker Compose (Easiest)
```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
cp .env.example .env
# Edit .env to set passwords
docker-compose up -d
```

### Method 2: Podman Deploy Script
```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
cp .env.example .env
# Edit .env to set passwords
./deploy-podman.sh
```

### Method 3: Podman Compose
```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
cp .env.example .env
# Edit .env to set passwords
podman-compose up -d
```

### Method 4: Makefile
```bash
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
make init-env  # Creates .env from template
# Edit .env to set passwords
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
├── 📄 ANALYSIS_SUMMARY.md          # Technical analysis
├── 🐳 Dockerfile                   # App server image
├── 🐳 Dockerfile.lookup            # Lookup server image
├── 📋 docker-compose.yml           # Docker orchestration
├── 📋 podman-compose.yml           # Podman orchestration
├── 🔧 Makefile                     # Management commands
├── 🚀 deploy-podman.sh             # Podman deployment
├── 🧪 test-deployment.sh           # Testing script
├── 📚 aeos_technical_help_en_compressed.pdf  # Original docs
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
3. ✅ Create .env file with secure passwords
4. ✅ Run deployment command
5. ✅ Access web interface
6. 📖 Read README_CONTAINER.md for detailed info
7. 📖 Read ANALYSIS_SUMMARY.md for technical details
8. 📄 Review aeos_technical_help_en_compressed.pdf for AEOS features

## Support

- **Container Issues**: Open issue on GitHub
- **AEOS Software**: Contact Nedap Security Management
- **Documentation**: See README_CONTAINER.md

---

**🎉 AEOS is now containerized and ready to use with Podman!**
