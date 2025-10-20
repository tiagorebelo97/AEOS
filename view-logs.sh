#!/bin/bash
# AEOS Log Viewer Script
# This script provides easy access to container logs

set -e

CONTAINER_RUNTIME=""

# Detect container runtime
if command -v podman &> /dev/null; then
    CONTAINER_RUNTIME="podman"
elif command -v docker &> /dev/null; then
    CONTAINER_RUNTIME="docker"
else
    echo "Error: Neither Podman nor Docker is installed"
    exit 1
fi

echo "=========================================="
echo "AEOS Log Viewer"
echo "Using: $CONTAINER_RUNTIME"
echo "=========================================="
echo ""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION] [CONTAINER]"
    echo ""
    echo "Options:"
    echo "  all           - Show logs from all AEOS containers (default)"
    echo "  server        - Show logs from AEOS server only"
    echo "  lookup        - Show logs from AEOS lookup server only"
    echo "  database      - Show logs from database only"
    echo "  follow        - Follow logs in real-time (all containers)"
    echo "  status        - Show container status"
    echo "  help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Show all logs"
    echo "  $0 all              # Show all logs"
    echo "  $0 server           # Show server logs"
    echo "  $0 follow           # Follow all logs in real-time"
    echo ""
}

# Function to check if container exists and is running
check_container() {
    local container=$1
    if ! $CONTAINER_RUNTIME ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "Warning: Container '${container}' does not exist"
        return 1
    fi
    return 0
}

# Function to show container status
show_status() {
    echo "Container Status:"
    echo "=========================================="
    $CONTAINER_RUNTIME ps -a --filter "name=aeos-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    # Show health status for each container
    for container in aeos-database aeos-lookup aeos-server; do
        if check_container "$container"; then
            state=$($CONTAINER_RUNTIME inspect --format='{{.State.Status}}' ${container} 2>/dev/null || echo "unknown")
            health=$($CONTAINER_RUNTIME inspect --format='{{.State.Health.Status}}' ${container} 2>/dev/null || echo "none")
            echo "${container}: ${state} (health: ${health})"
        fi
    done
    echo ""
}

# Function to show logs for a specific container
show_container_logs() {
    local container=$1
    local follow=${2:-false}
    
    if ! check_container "$container"; then
        return 1
    fi
    
    echo "=========================================="
    echo "Logs for: $container"
    echo "=========================================="
    
    if [ "$follow" = "true" ]; then
        echo "(Following logs... Press Ctrl+C to stop)"
        $CONTAINER_RUNTIME logs -f "$container"
    else
        $CONTAINER_RUNTIME logs --tail 100 "$container"
    fi
}

# Function to show all logs
show_all_logs() {
    for container in aeos-database aeos-lookup aeos-server; do
        if check_container "$container"; then
            echo ""
            show_container_logs "$container" false
            echo ""
        fi
    done
}

# Function to follow all logs
follow_all_logs() {
    echo "Following logs from all containers..."
    echo "(Press Ctrl+C to stop)"
    echo ""
    
    # Use exec to replace the current shell, so Ctrl+C works properly
    if [ "$CONTAINER_RUNTIME" = "podman" ]; then
        exec podman-compose logs -f 2>/dev/null || \
            exec bash -c "podman logs -f aeos-database 2>&1 | sed 's/^/[database] /' & \
                          podman logs -f aeos-lookup 2>&1 | sed 's/^/[lookup] /' & \
                          podman logs -f aeos-server 2>&1 | sed 's/^/[server] /' & \
                          wait"
    else
        exec docker-compose logs -f
    fi
}

# Main script logic
COMMAND=${1:-all}

case "$COMMAND" in
    help|-h|--help)
        show_usage
        ;;
    status)
        show_status
        ;;
    all)
        show_all_logs
        ;;
    server)
        show_container_logs "aeos-server" false
        ;;
    lookup)
        show_container_logs "aeos-lookup" false
        ;;
    database|db)
        show_container_logs "aeos-database" false
        ;;
    follow|-f)
        follow_all_logs
        ;;
    *)
        echo "Unknown option: $COMMAND"
        echo ""
        show_usage
        exit 1
        ;;
esac
