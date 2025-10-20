# AEOS Application Server Dockerfile
# This containerizes the AEOS access control system for use with Docker/Podman
# Uses the official AEOS installer from GitHub releases

FROM eclipse-temurin:11-jdk-jammy

LABEL maintainer="AEOS Container"
LABEL description="AEOS Access Control System Application Server"
LABEL version="2023.1.8"

# Set environment variables
ENV AEOS_HOME=/opt/aeos \
    AEOS_VERSION=2023.1.8 \
    JAVA_HOME=/opt/java/openjdk \
    JAVA_OPTS="-Xms2048m -Xmx4096m" \
    TZ=UTC

# Install required dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    postgresql-client \
    netcat-openbsd \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Download and install AEOS from GitHub releases
# The installer is a self-extracting shell script with the AEOS binaries
RUN echo "Downloading AEOS installer from GitHub releases..." \
    && wget -q --show-progress \
        "https://github.com/tiagorebelo97/AEOS/releases/download/version0/aeosinstall_${AEOS_VERSION}.sh" \
        -O /tmp/aeosinstall.sh \
    && chmod +x /tmp/aeosinstall.sh \
    && echo "Installing AEOS to ${AEOS_HOME}..." \
    && /tmp/aeosinstall.sh -s -d ${AEOS_HOME} \
    && rm -f /tmp/aeosinstall.sh \
    && echo "AEOS installation complete"

# Copy entrypoint and healthcheck scripts
COPY scripts/entrypoint.sh /usr/local/bin/
COPY scripts/healthcheck.sh /usr/local/bin/

# Make scripts executable
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/healthcheck.sh

# Expose AEOS ports
# 8080 - AEOS Web Interface (HTTP)
# 8443 - AEOS Web Interface (HTTPS)
# 2505 - AEOS Lookup Server (handled by separate container)
# 2506 - AEOS Application Server
EXPOSE 8080 8443 2506

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD /usr/local/bin/healthcheck.sh

# Set working directory
WORKDIR ${AEOS_HOME}

# Use entrypoint script to start AEOS server
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["run"]
