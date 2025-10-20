# AEOS Container - Quick Reference Card

## One-Line Summary
Run AEOS 2023.1.8 in containers using the official installer from GitHub releases - just clone and deploy!

## Prerequisites
- Docker 20.10+ or Podman 3.0+
- 8GB RAM (12GB for build)
- 50GB disk space
- Internet connection

## Quick Deploy (3 Commands)

### Docker
```bash
git clone https://github.com/tiagorebelo97/AEOS.git && cd AEOS
cp .env.example .env && nano .env  # Set passwords
docker-compose build && docker-compose up -d
```

### Podman
```bash
git clone https://github.com/tiagorebelo97/AEOS.git && cd AEOS
cp .env.example .env && nano .env  # Set passwords
./deploy-podman.sh
```

## Access AEOS
- **HTTP**: http://localhost:8080/aeos
- **HTTPS**: https://localhost:8443/aeos
- **Default Login**: admin/admin (change immediately)

## Common Commands

### Check Status
```bash
docker-compose ps              # Docker
podman ps -a                   # Podman
```

### View Logs
```bash
docker-compose logs -f         # Docker
podman logs -f aeos-server     # Podman
```

### Restart
```bash
docker-compose restart         # Docker
podman restart aeos-server     # Podman
```

### Stop
```bash
docker-compose down            # Docker
podman stop aeos-server        # Podman
```

## Build Details
- **First Build**: 10-20 minutes (downloads 1.4GB installer)
- **Subsequent Builds**: 1-2 minutes (uses cache)
- **Image Size**: ~4GB total
- **Source**: Official aeosinstall_2023.1.8.sh from GitHub releases

## What's Inside
```
Container: aeos-server
  • WildFly Application Server
  • AEOS Web Application
  • Ports: 8080 (HTTP), 8443 (HTTPS), 2506 (App)

Container: aeos-lookup
  • Jini Service Discovery
  • Port: 2505

Container: aeos-database
  • PostgreSQL 14
  • Port: 5432
  • Volume: aeos-db-data
```

## Ports
| Port | Service | Description |
|------|---------|-------------|
| 8080 | HTTP | AEOS Web Interface |
| 8443 | HTTPS | Secure Web Interface |
| 2505 | TCP | Lookup/Jini Service |
| 2506 | TCP | Application Server |
| 5432 | TCP | PostgreSQL Database |

## Important Files
- `.env` - Environment variables (passwords!)
- `docker-compose.yml` - Service orchestration
- `Dockerfile` - Application server build
- `Dockerfile.lookup` - Lookup server build

## Environment Variables
```bash
AEOS_DB_PASSWORD=your_secure_password_here
AEOS_DB_HOST=aeos-database
AEOS_DB_PORT=5432
AEOS_DB_NAME=aeos
AEOS_DB_USER=aeos
TZ=UTC
```

## Troubleshooting

### Build Fails
```bash
# Check internet
ping github.com

# Clean and retry
docker system prune -a
docker-compose build --no-cache
```

### Can't Access Web
```bash
# Check if running
docker-compose ps

# Check logs
docker-compose logs aeos-server

# Check port
curl http://localhost:8080
```

### Database Issues
```bash
# Check database
docker exec aeos-database pg_isready -U aeos

# View database logs
docker-compose logs aeos-database
```

### Out of Space
```bash
df -h                          # Check space
docker system prune -a         # Clean Docker
```

## VM Deployment
```bash
# On VM
git clone https://github.com/tiagorebelo97/AEOS.git
cd AEOS
cp .env.example .env
nano .env  # Edit settings

# Open firewall (if needed)
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp

# Deploy
docker-compose build
docker-compose up -d

# Access from other machines
http://vm-ip-address:8080/aeos
```

## Backup
```bash
# Backup database
docker exec aeos-database pg_dump -U aeos aeos > backup.sql

# Backup volumes
docker run --rm -v aeos-db-data:/data -v $(pwd):/backup alpine \
    tar czf /backup/aeos-backup.tar.gz /data
```

## Restore
```bash
# Restore database
cat backup.sql | docker exec -i aeos-database psql -U aeos aeos
```

## Update AEOS
```bash
git pull
docker-compose build
docker-compose up -d
```

## Documentation Map
- **QUICKSTART.md** - Fast track guide (you are here!)
- **BUILD.md** - Build process details
- **VM_DEPLOYMENT.md** - VM-specific deployment
- **WORKFLOW.md** - Visual workflow diagrams
- **README_CONTAINER.md** - Complete container guide
- **IMPLEMENTATION_SUMMARY.md** - Technical summary

## Key URLs
- **Repository**: https://github.com/tiagorebelo97/AEOS
- **Releases**: https://github.com/tiagorebelo97/AEOS/releases/tag/version0
- **Installer**: aeosinstall_2023.1.8.sh (1.4GB)

## What Makes This Special
✅ Uses **official AEOS binaries** from GitHub releases  
✅ **Automated** download and installation  
✅ **Production-ready** with real WildFly server  
✅ **Portable** - runs anywhere with Docker/Podman  
✅ **Reproducible** - same result every time  
✅ **VM-friendly** - perfect for VM deployment  

## Support
- **Container Issues**: GitHub issues
- **AEOS Software**: Nedap Security Management
- **Documentation**: See docs in repository

## Security Notes
⚠️ Change default passwords in .env  
⚠️ Use HTTPS in production  
⚠️ Keep containers updated  
⚠️ Enable firewall  
⚠️ Regular backups  

## Next Steps
1. ✅ Deploy containers
2. ✅ Change admin password
3. ✅ Configure for your environment
4. 📖 Read full docs for advanced features
5. 📖 Review AEOS manual for usage

---

**Version**: 2023.1.8  
**Status**: Production Ready  
**Last Updated**: October 2025
