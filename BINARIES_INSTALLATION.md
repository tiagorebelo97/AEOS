# AEOS Binaries Installation Guide

## Overview

This guide explains how to add AEOS software binaries to the containerized deployment. The binaries directory structure has been created to make it easy to install AEOS software into the Docker/Podman containers.

## What Changed

The repository now includes a `binaries/` directory with two subdirectories:

```
binaries/
├── README.md              # Detailed instructions
├── app-server/            # Place AEOS WAR files here
│   └── .gitkeep           # Preserves directory in git
└── lookup-server/         # Place AEOS JAR files here
    └── .gitkeep           # Preserves directory in git
```

## Why This Matters

Previously, the Dockerfiles didn't copy any actual AEOS application binaries. They only set up the infrastructure (Tomcat, Java, PostgreSQL) but were missing the actual AEOS software.

Now, when you place your AEOS binaries in the correct directories and run `docker-compose build`, the build process will:

1. **For Application Server**: Copy all `.war` files from `binaries/app-server/` to Tomcat's webapps directory
2. **For Lookup Server**: Copy all `.jar` files from `binaries/lookup-server/` to the lookup server's bin directory

## Installation Workflow

### Step 1: Obtain AEOS Software

Contact Nedap Security Management to obtain:
- AEOS installation package
- Valid license file or key
- Contact: https://www.nedapsecurity.com/

### Step 2: Extract Binaries

From your AEOS installation package, extract:
- **Application Server**: `aeos.war` (or similar name)
- **Lookup Server**: `aeos-lookup.jar` (or similar name)
- Any additional required libraries

### Step 3: Place Binaries

Copy the binaries to the correct locations:

```bash
cd AEOS/

# Copy application server WAR
cp /path/to/your/aeos.war binaries/app-server/

# Copy lookup server JAR
cp /path/to/your/aeos-lookup.jar binaries/lookup-server/

# If you have additional JAR dependencies for lookup server
cp /path/to/lib/*.jar binaries/lookup-server/
```

### Step 4: Verify Placement

Check that files are in the correct locations:

```bash
# Should show your WAR file(s)
ls -lh binaries/app-server/

# Should show your JAR file(s)
ls -lh binaries/lookup-server/
```

### Step 5: Build Containers

Build the container images (this copies binaries into the images):

```bash
# Using Docker
docker-compose build

# Using Podman
podman-compose build
# OR
./deploy-podman.sh
```

During the build, you should see output like:
```
Step X/Y : COPY binaries/app-server/*.war /usr/local/tomcat/webapps/
Step X/Y : COPY binaries/lookup-server/*.jar /opt/aeos-lookup/bin/
```

### Step 6: Deploy

Start the containers:

```bash
# Using Docker
docker-compose up -d

# Using Podman
podman-compose up -d
# OR
./deploy-podman.sh
```

### Step 7: Verify Deployment

Check that binaries were deployed:

```bash
# Check application server logs
docker-compose logs aeos-server
# Look for: "Found X WAR file(s) in webapps directory"

# Check lookup server logs
docker-compose logs aeos-lookup
# Look for: "Found lookup server JAR: /opt/aeos-lookup/bin/..."
```

Access the web interface: http://localhost:8080/aeos

## File Naming

The Dockerfiles use wildcards, so they will copy:
- **All files** ending in `.war` from `binaries/app-server/`
- **All files** ending in `.jar` from `binaries/lookup-server/`

You can name your files anything as long as they have the correct extension.

## Common Issues

### Build fails with "no source files were specified"

**Cause**: No binaries were placed in the directories before building.

**Solution**: 
1. Place your AEOS WAR and JAR files in the correct directories
2. Verify they exist with `ls binaries/*/`
3. Run the build again

### Container starts but AEOS is not accessible

**Cause**: Binaries may not have been copied during build, or wrong file types.

**Solution**:
1. Check container logs: `docker-compose logs aeos-server`
2. Verify WAR file was deployed: `docker exec aeos-server ls -lh /usr/local/tomcat/webapps/`
3. Rebuild if needed: `docker-compose build --no-cache`

### Git shows my binaries as modified/untracked

**Cause**: The `.gitignore` should be excluding binaries.

**Solution**:
- This is normal - binaries should NOT be committed to git
- Only `.gitkeep` files and `README.md` should be tracked in the binaries directory
- The `.gitignore` is configured to exclude `*.war`, `*.jar`, and other binary files

## Security Notes

🔒 **Do not commit binaries to version control**

- Binary files are excluded by `.gitignore`
- Only commit the directory structure (`.gitkeep` files)
- Binaries must be obtained legally from Nedap
- Each user must place their own licensed binaries

## What Gets Copied Where

### Application Server (Dockerfile)

```dockerfile
COPY binaries/app-server/*.war ${CATALINA_HOME}/webapps/
```

This copies to: `/usr/local/tomcat/webapps/`

Tomcat automatically deploys WAR files in this directory on startup.

### Lookup Server (Dockerfile.lookup)

```dockerfile
COPY binaries/lookup-server/*.jar ${AEOS_LOOKUP_HOME}/bin/
```

This copies to: `/opt/aeos-lookup/bin/`

The entrypoint script finds and executes the JAR file on startup.

## Advanced Usage

### Multiple WAR Files

You can place multiple WAR files in `binaries/app-server/` and all will be deployed:

```bash
binaries/app-server/
├── aeos.war
├── aeos-admin.war
└── aeos-api.war
```

### Additional JAR Libraries

For lookup server dependencies:

```bash
binaries/lookup-server/
├── aeos-lookup.jar          # Main application
├── dependency-1.jar         # Additional library
├── dependency-2.jar         # Additional library
└── ...
```

All JARs are added to the classpath automatically.

### Rebuilding After Binary Updates

If you update your binaries:

```bash
# Update binaries
cp /path/to/new/aeos.war binaries/app-server/

# Rebuild (without cache to ensure fresh copy)
docker-compose build --no-cache

# Restart containers
docker-compose down
docker-compose up -d
```

## Additional Resources

- **Detailed Binary Placement**: See [binaries/README.md](binaries/README.md)
- **Container Setup**: See [README_CONTAINER.md](README_CONTAINER.md)
- **Quick Start**: See [QUICKSTART.md](QUICKSTART.md)
- **AEOS Documentation**: See `aeos_technical_help_en_compressed.pdf`

## Support

- **AEOS Software/Licensing**: Contact Nedap Security Management
- **Container Issues**: Open an issue on GitHub
- **Binary Placement Questions**: See [binaries/README.md](binaries/README.md)

---

**Remember**: The binaries directory is designed to automatically integrate AEOS software into the containers. Just place the files and build!
