# AEOS Application Server Dockerfile
# This containerizes the AEOS access control system for use with Docker/Podman

FROM tomcat:9-jdk11-openjdk

LABEL maintainer="AEOS Container"
LABEL description="AEOS Access Control System Application Server"
LABEL version="2023.1.x"

# Install required dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    postgresql-client \
    mysql-client \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV CATALINA_HOME=/usr/local/tomcat \
    AEOS_HOME=/opt/aeos \
    AEOS_DATA=/var/lib/aeos \
    JAVA_OPTS="-Xms2048m -Xmx4096m -XX:MaxPermSize=512m" \
    TZ=UTC

# Create AEOS directories
RUN mkdir -p ${AEOS_HOME} \
    && mkdir -p ${AEOS_DATA}/logs \
    && mkdir -p ${AEOS_DATA}/config \
    && mkdir -p ${AEOS_DATA}/data \
    && mkdir -p ${CATALINA_HOME}/webapps

# Copy AEOS application binaries
# Place your AEOS WAR files in binaries/app-server/ before building
COPY binaries/app-server/*.war ${CATALINA_HOME}/webapps/

# Copy AEOS configuration template
COPY config/aeos.properties.template ${AEOS_DATA}/config/
COPY config/server.xml ${CATALINA_HOME}/conf/server.xml
COPY scripts/entrypoint.sh /usr/local/bin/
COPY scripts/healthcheck.sh /usr/local/bin/

# Make scripts executable
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/healthcheck.sh

# Expose AEOS ports
# 8080 - AEOS Web Interface (HTTP)
# 8443 - AEOS Web Interface (HTTPS)
# 2505 - AEOS Lookup Server
# 2506 - AEOS Application Server
EXPOSE 8080 8443 2505 2506

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Set working directory
WORKDIR ${AEOS_HOME}

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["catalina.sh", "run"]
