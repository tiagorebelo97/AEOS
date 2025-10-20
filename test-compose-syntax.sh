#!/bin/bash
# Test script to validate compose file syntax
# This ensures that the healthcheck commands are properly formatted

set -e

echo "========================================"
echo "Compose File Syntax Validation"
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
        return 1
    fi
}

# Test YAML syntax
echo "=== Validating YAML Syntax ==="
run_test "docker-compose.yml YAML syntax" "python3 -c 'import yaml; yaml.safe_load(open(\"docker-compose.yml\"))'"
run_test "podman-compose.yml YAML syntax" "python3 -c 'import yaml; yaml.safe_load(open(\"podman-compose.yml\"))'"
echo ""

# Test with docker compose if available
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    echo "=== Validating with Docker Compose ==="
    run_test "docker-compose.yml config validation" "docker compose -f docker-compose.yml config > /dev/null"
    run_test "podman-compose.yml config validation" "docker compose -f podman-compose.yml config > /dev/null"
    echo ""
fi

# Check healthcheck format is correct (using CMD, not CMD-SHELL)
echo "=== Checking Healthcheck Format ==="
run_test "docker-compose.yml uses CMD format" "! grep -q 'CMD-SHELL' docker-compose.yml"
run_test "podman-compose.yml uses CMD format" "! grep -q 'CMD-SHELL' podman-compose.yml"
echo ""

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✓ All compose syntax tests passed!"
    exit 0
else
    echo "✗ Some tests failed. Please check the output above."
    exit 1
fi
