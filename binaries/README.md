# AEOS Binaries Directory

This directory is where you should place the AEOS software binaries obtained from Nedap Security Management.

## Required Files

### Application Server (`binaries/app-server/`)

Place the AEOS application server WAR file here:

```
binaries/app-server/
└── aeos.war          # Main AEOS web application (required)
```

**Expected file**: `aeos.war` or similar name
**Purpose**: This is the main AEOS web application that runs on Tomcat

### Lookup Server (`binaries/lookup-server/`)

Place the AEOS lookup server JAR files here:

```
binaries/lookup-server/
├── aeos-lookup.jar           # Main lookup server (required)
└── aeos-lookup-libs/         # Dependencies (if separate)
    ├── dependency1.jar
    ├── dependency2.jar
    └── ...
```

**Expected files**: 
- Main lookup server JAR file
- Any required dependency JARs or libraries

## How to Obtain AEOS Binaries

⚠️ **Important**: AEOS is proprietary software that requires a valid license from Nedap Security Management.

1. **Contact Nedap**: Visit https://www.nedapsecurity.com/
2. **Request AEOS Software**: Ask for the AEOS installation package
3. **Obtain License**: Get your license file or license key
4. **Extract Binaries**: From the installation package, extract:
   - The AEOS web application (`.war` file)
   - The lookup server application (`.jar` file)
   - Any required libraries

## Installation Instructions

### Step 1: Place Binaries

Copy your AEOS binaries to this directory:

```bash
# Copy application server WAR file
cp /path/to/your/aeos.war binaries/app-server/

# Copy lookup server JAR file
cp /path/to/your/aeos-lookup.jar binaries/lookup-server/

# If you have additional libraries
cp -r /path/to/libs/* binaries/lookup-server/
```

### Step 2: Build Containers

Once the binaries are in place, build the containers:

```bash
# Using Docker
docker-compose build

# Using Podman
podman-compose build

# Using Makefile
make build          # Docker
make build-podman   # Podman
```

The Dockerfiles will automatically copy the binaries into the container images during the build process.

### Step 3: Deploy

After building, deploy the containers:

```bash
# Using Docker
docker-compose up -d

# Using Podman
./deploy-podman.sh

# Using Makefile
make up             # Docker
make up-podman      # Podman
```

## What Happens During Build?

When you run `docker-compose build` or `podman-compose build`:

1. **Application Server**:
   - The `Dockerfile` copies `binaries/app-server/*.war` to `/usr/local/tomcat/webapps/`
   - Tomcat automatically deploys the WAR file on startup
   - The application becomes available at `http://localhost:8080/aeos`

2. **Lookup Server**:
   - The `Dockerfile.lookup` copies `binaries/lookup-server/*.jar` to `/opt/aeos-lookup/bin/`
   - The entrypoint script starts the lookup server JAR
   - The server listens on port 2505

## Verification

After placing binaries, verify they are in the correct location:

```bash
# Check binaries are present
ls -lh binaries/app-server/
ls -lh binaries/lookup-server/

# Should show your WAR and JAR files
```

## Troubleshooting

### No binaries found during build

**Error**: `COPY failed: no source files were specified`

**Solution**: Ensure you have placed the AEOS binaries in the correct directories before running `build`.

### Wrong file types

**Error**: Application fails to start or deploy

**Solution**: 
- Verify you have the correct file types (`.war` for app server, `.jar` for lookup server)
- Check file permissions are readable
- Ensure files are not corrupted

### Missing dependencies

**Error**: `ClassNotFoundException` or similar in logs

**Solution**: 
- Copy all required dependency JARs to `binaries/lookup-server/`
- Check Nedap documentation for complete list of required libraries

## File Naming

The Dockerfiles expect these naming patterns:

- **Application Server**: Any file with `.war` extension in `binaries/app-server/`
- **Lookup Server**: Any file with `.jar` extension in `binaries/lookup-server/`

If you have differently named files, they will still be copied, but you may need to adjust the entrypoint scripts to reference the correct filenames.

## Security Note

🔒 **Do not commit binaries to version control**

The `.gitignore` file is configured to exclude binary files. This prevents:
- Large files in git history
- Licensing violations
- Proprietary software distribution

Only commit the directory structure, not the actual binaries.

## Support

- **AEOS Software Issues**: Contact Nedap Security Management
- **Container/Build Issues**: Open an issue on this repository
- **Documentation**: See main README.md and README_CONTAINER.md

## License

AEOS software is proprietary and owned by Nedap Security Management. Only use with a valid license.
