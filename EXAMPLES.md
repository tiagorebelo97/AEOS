# Example: Adding Your Application to the AEOS Container

This file demonstrates how to add a simple application to the AEOS container.

## Example 1: Python Application

If AEOS is a Python application:

### 1. Update Containerfile

```dockerfile
FROM ubuntu:22.04

LABEL maintainer="AEOS Project"
LABEL description="AEOS - Linux based application container"
LABEL version="1.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install Python and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -s /bin/bash aeos

WORKDIR /app

# Copy application files
COPY requirements.txt /app/
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . /app/

RUN chown -R aeos:aeos /app

USER aeos

# Start your Python application
CMD ["python3", "main.py"]

EXPOSE 8080
```

## Example 2: Node.js Application

If AEOS is a Node.js application:

### 1. Update Containerfile

```dockerfile
FROM ubuntu:22.04

LABEL maintainer="AEOS Project"
LABEL description="AEOS - Linux based application container"
LABEL version="1.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install Node.js
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -s /bin/bash aeos

WORKDIR /app

# Copy package files
COPY package*.json /app/

# Install dependencies as root
RUN npm ci --only=production

# Copy application files
COPY . /app/

RUN chown -R aeos:aeos /app

USER aeos

# Start your Node.js application
CMD ["node", "server.js"]

EXPOSE 3000
```

## Example 3: Go Application

If AEOS is a Go application:

### 1. Update Containerfile (Multi-stage build)

```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /build

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o aeos .

# Runtime stage
FROM ubuntu:22.04

LABEL maintainer="AEOS Project"
LABEL description="AEOS - Linux based application container"
LABEL version="1.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -s /bin/bash aeos

WORKDIR /app

# Copy binary from builder
COPY --from=builder /build/aeos /app/aeos

RUN chown -R aeos:aeos /app

USER aeos

CMD ["./aeos"]

EXPOSE 8080
```

## Example 4: Bash Script Application

If AEOS is a collection of bash scripts:

### 1. Update Containerfile

```dockerfile
FROM ubuntu:22.04

LABEL maintainer="AEOS Project"
LABEL description="AEOS - Linux based application container"
LABEL version="1.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    util-linux \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -s /bin/bash aeos

WORKDIR /app

# Copy scripts
COPY scripts/ /app/scripts/
COPY entrypoint.sh /app/

RUN chmod +x /app/entrypoint.sh /app/scripts/*.sh

RUN chown -R aeos:aeos /app

USER aeos

CMD ["./entrypoint.sh"]
```

## Testing Your Changes

After modifying the Containerfile:

1. **Rebuild the container:**
   ```bash
   make build
   ```

2. **Test it works:**
   ```bash
   make run
   ```

3. **Check logs if running detached:**
   ```bash
   make run-detached
   make logs
   ```

4. **Debug inside the container:**
   ```bash
   podman run -it --rm aeos:latest /bin/bash
   ```

## Environment-Specific Configuration

Use environment variables for configuration:

```yaml
# In podman-compose.yml
environment:
  - DATABASE_URL=postgresql://localhost/aeos
  - APP_ENV=production
  - LOG_LEVEL=info
```

Or in Makefile/scripts:
```bash
podman run -it --rm \
  -e DATABASE_URL=postgresql://localhost/aeos \
  -e APP_ENV=production \
  aeos:latest
```
