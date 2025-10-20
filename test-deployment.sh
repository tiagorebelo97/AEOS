#!/bin/bash
# Test script for AEOS container deployment

set -e

echo "========================================"
echo "AEOS Container Deployment Test"
echo "========================================"
echo ""

FAILED=0
PASSED=0

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    if eval "$test_command" > /dev/null 2>&1; then
        echo "✓ PASSED"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAILED"
        FAILED=$((FAILED + 1))
    fi
}

# Check if Docker/Podman is installed
echo "=== Checking Prerequisites ==="
run_test "Docker installed" "command -v docker"
run_test "Docker Compose installed" "command -v docker-compose"
run_test "Podman installed" "command -v podman"
echo ""

# Check if .env exists
echo "=== Checking Configuration ==="
run_test ".env file exists" "test -f .env"
run_test "Configuration directory exists" "test -d config"
run_test "Scripts directory exists" "test -d scripts"
echo ""

# Check if containers are running (Docker)
echo "=== Checking Docker Containers ==="
run_test "Database container running" "docker ps | grep -q aeos-database"
run_test "Lookup server running" "docker ps | grep -q aeos-lookup"
run_test "Application server running" "docker ps | grep -q aeos-server"
echo ""

# Check network connectivity
echo "=== Checking Network Connectivity ==="
run_test "Database port accessible" "nc -z localhost 5432"
run_test "Lookup server port accessible" "nc -z localhost 2505"
run_test "Web interface port accessible" "nc -z localhost 8080"
echo ""

# Check health endpoints
echo "=== Checking Service Health ==="
run_test "Database health check" "docker exec aeos-database pg_isready -U aeos"
run_test "Web interface responds" "curl -f -s http://localhost:8080 > /dev/null"
echo ""

# Check volumes
echo "=== Checking Data Persistence ==="
run_test "Database volume exists" "docker volume ls | grep -q aeos-db-data"
run_test "Application data volume exists" "docker volume ls | grep -q aeos-data"
run_test "Logs volume exists" "docker volume ls | grep -q aeos-logs"
echo ""

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✓ All tests passed!"
    exit 0
else
    echo "✗ Some tests failed. Please check the output above."
    exit 1
fi
