# AEOS Container Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         AEOS System                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    User Access Layer                      │  │
│  │                                                            │  │
│  │  HTTP:  http://localhost:8080                            │  │
│  │  HTTPS: https://localhost:8443                           │  │
│  └────────────────────┬─────────────────────────────────────┘  │
│                       │                                          │
│                       ▼                                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              aeos-server Container                        │  │
│  │                                                            │  │
│  │  • AEOS Application Server                               │  │
│  │  • Java 11 (Eclipse Temurin)                             │  │
│  │  • Memory: 2GB-4GB                                        │  │
│  │  • Ports: 8080, 8443, 2506                               │  │
│  │  • Health Check: Port 2506 availability                  │  │
│  │                                                            │  │
│  │  Entrypoint: /usr/local/bin/entrypoint.sh                │  │
│  │  - Waits for database health                             │  │
│  │  - Waits for lookup server                               │  │
│  │  - Configures connections                                │  │
│  │  - Starts AEOS server                                    │  │
│  └────────────┬──────────────────────┬──────────────────────┘  │
│               │                      │                          │
│               ▼                      ▼                          │
│  ┌────────────────────────┐ ┌──────────────────────────────┐  │
│  │  aeos-lookup Container │ │  aeos-database Container     │  │
│  │                        │ │                              │  │
│  │  • AEOS Lookup Server │ │  • PostgreSQL 14 Alpine      │  │
│  │  • Java 11            │ │  • Database: aeos            │  │
│  │  • Memory: 512MB-1GB  │ │  • User: aeos                │  │
│  │  • Port: 2505         │ │  • Port: 5432                │  │
│  │  • Health: Port check │ │  • Health: pg_isready        │  │
│  │                        │ │  • Volume: aeos-db-data      │  │
│  │  Entrypoint:          │ │                              │  │
│  │  - Waits for DB       │ │  Health Check:               │  │
│  │  - Configures DB      │ │  - Every 10s                 │  │
│  │  - Starts lookup      │ │  - Start period: 10s         │  │
│  └────────────┬───────────┘ │  - Retries: 5                │  │
│               │              └──────────────────────────────┘  │
│               │                      ▲                          │
│               └──────────────────────┘                          │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  aeos-network (bridge)                    │  │
│  │                                                            │  │
│  │  Internal DNS:                                            │  │
│  │  - aeos-database (resolves to container IP)              │  │
│  │  - aeos-lookup (resolves to container IP)                │  │
│  │  - aeos-server (resolves to container IP)                │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Startup Sequence

```
Step 1: docker-compose up
  │
  ├─> Create aeos-network (bridge network)
  │
  └─> Create aeos-db-data (volume for database persistence)

Step 2: Start aeos-database
  │
  ├─> Pull postgres:14-alpine image
  ├─> Create container
  ├─> Start PostgreSQL
  ├─> Initialize database
  │   ├─> Create database 'aeos'
  │   ├─> Create user 'aeos'
  │   └─> Set encoding to UTF8
  │
  └─> Health check loop (every 10s)
      ├─> Run: pg_isready -U aeos -d aeos
      ├─> Retries: 5 attempts
      └─> Status: healthy ✓

Step 3: Start aeos-lookup (waits for database healthy)
  │
  ├─> Build Dockerfile.lookup
  │   ├─> Base: eclipse-temurin:11-jdk-jammy
  │   ├─> Install dependencies (wget, netcat, curl, procps)
  │   ├─> Download AEOS installer from GitHub
  │   ├─> Install AEOS to /opt/aeos
  │   └─> Copy entrypoint and healthcheck scripts
  │
  ├─> Start container
  │
  ├─> Execute: /usr/local/bin/lookup-entrypoint.sh
  │   │
  │   ├─> Wait for database port 5432 (max 60s)
  │   │   └─> Check: nc -z aeos-database 5432
  │   │
  │   ├─> Configure database connection
  │   │   └─> Update: /opt/aeos/config/database.properties
  │   │
  │   └─> Start AEOS Lookup Server
  │       └─> Execute: /opt/aeos/bin/aeoslookup start
  │
  └─> Health check (every 30s)
      ├─> Check process: pgrep -f "aeoslookup"
      └─> Check port: nc -z localhost 2505

Step 4: Start aeos-server (waits for database + lookup)
  │
  ├─> Build Dockerfile.server
  │   ├─> Base: eclipse-temurin:11-jdk-jammy
  │   ├─> Install dependencies (wget, postgresql-client, netcat, curl)
  │   ├─> Download AEOS installer from GitHub
  │   ├─> Install AEOS to /opt/aeos
  │   └─> Copy entrypoint and healthcheck scripts
  │
  ├─> Start container
  │
  ├─> Execute: /usr/local/bin/entrypoint.sh
  │   │
  │   ├─> Wait for database port 5432 (max 60s)
  │   │   └─> Check: nc -z aeos-database 5432
  │   │
  │   ├─> Wait for lookup port 2505 (max 60s)
  │   │   └─> Check: nc -z aeos-lookup 2505
  │   │
  │   ├─> Configure database connection
  │   │   └─> Update: /opt/aeos/config/database.properties
  │   │
  │   ├─> Configure lookup server connection
  │   │   └─> Update: /opt/aeos/config/server.properties
  │   │
  │   └─> Start AEOS Application Server
  │       └─> Execute: /opt/aeos/bin/aeosserver run
  │
  └─> Health check (every 30s)
      ├─> Check process: pgrep -f "aeosserver"
      └─> Check port: nc -z localhost 2506

Step 5: System Ready ✓
  │
  └─> All services running and healthy
```

## Dependencies Graph

```
┌─────────────────┐
│ aeos-database   │ ◄───┐
│                 │     │
│ depends_on:     │     │ waits for
│   (none)        │     │ service_healthy
└─────────────────┘     │
                        │
┌─────────────────┐     │
│ aeos-lookup     │ ────┘
│                 │
│ depends_on:     │
│   database:     │
│     healthy     │
└─────────────────┘
         ▲
         │ waits for
         │ service_started
         │
┌─────────────────┐
│ aeos-server     │
│                 │
│ depends_on:     │
│   database:     │ ────┐
│     healthy     │     │ waits for
│   lookup:       │ ────┤ service_healthy
│     started     │     │
└─────────────────┘     │
                        │
                   ┌────▼────┐
                   │ database│
                   └─────────┘
```

## Health Check Flow

```
Database Health Check (every 10s):
┌─────────────────────────────────────┐
│ pg_isready -U aeos -d aeos         │
├─────────────────────────────────────┤
│ Success: database accepting conns   │ → healthy
│ Failure: retry (max 5 times)       │ → unhealthy
│ Start period: 10s                   │
└─────────────────────────────────────┘

Lookup Health Check (every 30s):
┌─────────────────────────────────────┐
│ 1. pgrep -f "aeoslookup"           │ → Process check
│ 2. nc -z localhost 2505             │ → Port check
├─────────────────────────────────────┤
│ Both succeed: healthy               │ → healthy
│ Any fails: retry (max 3 times)     │ → unhealthy
│ Start period: 30s                   │
└─────────────────────────────────────┘

Server Health Check (every 30s):
┌─────────────────────────────────────┐
│ 1. pgrep -f "aeosserver"           │ → Process check
│ 2. nc -z localhost 2506             │ → Port check
├─────────────────────────────────────┤
│ Both succeed: healthy               │ → healthy
│ Any fails: retry (max 5 times)     │ → unhealthy
│ Start period: 120s                  │
└─────────────────────────────────────┘
```

## Network Communication

```
External Clients
       │
       ▼
┌──────────────┐
│ Host System  │
└──────┬───────┘
       │
       │ Port Mappings:
       │ 5432 → aeos-database:5432
       │ 2505 → aeos-lookup:2505
       │ 2506 → aeos-server:2506
       │ 8080 → aeos-server:8080
       │ 8443 → aeos-server:8443
       │
       ▼
┌──────────────────────────────────────┐
│       aeos-network (bridge)          │
│                                      │
│  Container-to-Container DNS:         │
│  • aeos-database:5432               │
│  • aeos-lookup:2505                 │
│  • aeos-server:2506, 8080, 8443    │
└──────────────────────────────────────┘
```

## Volume Mounting

```
Host System                    Container
                              
┌─────────────────┐           ┌──────────────────────────┐
│ Docker/Podman   │           │ aeos-database            │
│ Volume Storage  │           │                          │
│                 │  Mount    │                          │
│ aeos-db-data    │ ────────► │ /var/lib/postgresql/data │
│                 │           │                          │
│ Persistent DB   │           │ • Database files         │
│ files stored    │           │ • WAL logs               │
│ here            │           │ • Configuration          │
└─────────────────┘           └──────────────────────────┘
```

## File System Layout (Inside Containers)

```
aeos-server & aeos-lookup:
/
├── opt/
│   └── aeos/                      # AEOS installation
│       ├── bin/                   # Executables
│       │   ├── aeosserver        # Server binary
│       │   └── aeoslookup        # Lookup binary
│       ├── config/                # Configuration
│       │   ├── database.properties
│       │   └── server.properties
│       ├── logs/                  # Application logs
│       │   ├── server.log
│       │   └── lookup.log
│       └── lib/                   # Java libraries
│
└── usr/local/bin/
    ├── entrypoint.sh              # Startup script
    ├── lookup-entrypoint.sh       # Lookup startup
    ├── healthcheck.sh             # Health check
    └── lookup-healthcheck.sh      # Lookup health

aeos-database:
/var/lib/postgresql/data/          # Database storage
├── base/                          # Database files
├── pg_wal/                        # Write-ahead logs
├── pg_log/                        # PostgreSQL logs
├── postgresql.conf                # Configuration
└── pg_hba.conf                    # Access control
```

## Environment Variables

```
Common:
- POSTGRES_PASSWORD             # Set in .env file

aeos-database:
- POSTGRES_DB=aeos             # Database name
- POSTGRES_USER=aeos           # Database user
- POSTGRES_INITDB_ARGS         # Encoding settings

aeos-lookup:
- AEOS_HOME=/opt/aeos          # Installation directory
- AEOS_VERSION=2023.1.8        # AEOS version
- AEOS_LOOKUP_PORT=2505        # Lookup server port
- AEOS_DB_HOST=aeos-database   # Database hostname
- AEOS_DB_PORT=5432            # Database port
- AEOS_DB_NAME=aeos            # Database name
- AEOS_DB_USER=aeos            # Database user
- AEOS_DB_PASSWORD             # Database password
- JAVA_OPTS=-Xms512m -Xmx1024m # JVM settings

aeos-server:
- AEOS_HOME=/opt/aeos          # Installation directory
- AEOS_VERSION=2023.1.8        # AEOS version
- AEOS_SERVER_PORT=2506        # Server port
- AEOS_DB_HOST=aeos-database   # Database hostname
- AEOS_DB_PORT=5432            # Database port
- AEOS_DB_NAME=aeos            # Database name
- AEOS_DB_USER=aeos            # Database user
- AEOS_DB_PASSWORD             # Database password
- AEOS_LOOKUP_HOST=aeos-lookup # Lookup hostname
- AEOS_LOOKUP_PORT=2505        # Lookup port
- JAVA_OPTS=-Xms2048m -Xmx4096m # JVM settings
- TZ=UTC                       # Timezone
```

## Resource Requirements

```
Minimum System Requirements:
- CPU: 2 cores
- RAM: 6 GB
  ├─> Database: 512 MB
  ├─> Lookup:   1 GB
  └─> Server:   4 GB
- Disk: 10 GB (5 GB for data)

Recommended:
- CPU: 4 cores
- RAM: 8 GB
  ├─> Database: 1 GB
  ├─> Lookup:   1 GB
  └─> Server:   6 GB
- Disk: 50 GB (for logs and data growth)
```

## Security Model

```
┌─────────────────────────────────────────┐
│         Host Firewall                    │
│  • Only expose needed ports             │
│  • Block internal ports (5432, 2505)    │
│    from external access if needed       │
└─────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│       Container Network Isolation        │
│  • Bridge network: aeos-network         │
│  • Containers can only talk to each     │
│    other through this network           │
│  • No access to other Docker networks   │
└─────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│      Application Security                │
│  • Database password in .env (excluded  │
│    from git)                            │
│  • No hardcoded credentials             │
│  • HTTPS support (port 8443)            │
└─────────────────────────────────────────┘
```
