# AEOS

AEOS Access Control System - Containerized Deployment

## Quick Start

Run AEOS with Docker or Podman in just one command:

```bash
./start.sh
```

That's it! The script will automatically:
- Detect your container runtime (Docker or Podman)
- Generate a secure database password
- Build and start all services
- Display status and helpful commands

## What Gets Started

- **AEOS Application Server** - Access on http://localhost:8080 or https://localhost:8443
- **AEOS Lookup Server** - Running on port 2505
- **PostgreSQL Database** - Running on port 5432

## Documentation

- **[CONTAINERIZATION.md](CONTAINERIZATION.md)** - Complete setup and configuration guide
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Detailed troubleshooting and log locations
- **[SOLUTION.md](SOLUTION.md)** - Technical details about the containerization solution
- **[aeos_technical_help_en_compressed.pdf](aeos_technical_help_en_compressed.pdf)** - AEOS technical documentation

## Common Commands

### View Logs
```bash
# All services
docker-compose logs -f

# Individual services
docker-compose logs -f aeos-database
docker-compose logs -f aeos-lookup
docker-compose logs -f aeos-server
```

### Check Status
```bash
docker-compose ps
```

### Stop Services
```bash
docker-compose down
```

### Restart Services
```bash
docker-compose restart
```

## Requirements

- Docker or Podman
- docker-compose or podman-compose

## Getting Help

If containers are not starting properly:
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed diagnostics
2. View logs with `docker-compose logs -f`
3. Check container health with `docker-compose ps`

For issues, please visit: https://github.com/tiagorebelo97/AEOS/issues