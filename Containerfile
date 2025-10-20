# Containerfile for AEOS
# This file is compatible with both Podman and Docker

# Use a minimal Linux base image
FROM ubuntu:22.04

# Set metadata labels
LABEL maintainer="AEOS Project"
LABEL description="AEOS - Linux based application container"
LABEL version="1.0"

# Set environment variables to prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Update system and install common dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for running the application
RUN useradd -m -u 1000 -s /bin/bash aeos

# Set working directory
WORKDIR /app

# Copy application files (when they exist)
# COPY . /app/

# Change ownership to non-root user
RUN chown -R aeos:aeos /app

# Switch to non-root user
USER aeos

# Set the default command
# Replace this with your application's start command
CMD ["/bin/bash"]

# Expose ports if needed
# EXPOSE 8080
