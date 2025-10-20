#!/bin/bash
# AEOS Container Quick Start
# This script helps you get started with the AEOS container

set -e

cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                  AEOS Container Quick Start                    ║
╚═══════════════════════════════════════════════════════════════╝

This repository is now containerized for Podman!

QUICK START:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Build the container:
   $ make build

2. Run the container:
   $ make run

3. See all available commands:
   $ make help

ALTERNATIVE METHODS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Using shell scripts:
  $ ./build-container.sh
  $ ./run-container.sh

Using Podman directly:
  $ podman build -t aeos:latest -f Containerfile .
  $ podman run -it --rm aeos:latest

Using podman-compose (if installed):
  $ podman-compose -f podman-compose.yml up

DOCUMENTATION:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• README.md           - Main documentation
• CONTAINER_GUIDE.md  - Detailed container usage guide
• EXAMPLES.md         - Language-specific integration examples

PREREQUISITES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Podman must be installed:
  Ubuntu/Debian: $ sudo apt install podman
  Fedora:        $ sudo dnf install podman
  macOS:         $ brew install podman
  Or visit:      https://podman.io/

NEXT STEPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Add your AEOS application code
2. Customize the Containerfile for your needs
3. Update ports, volumes, and environment variables
4. See EXAMPLES.md for guidance

╚═══════════════════════════════════════════════════════════════╝
EOF

echo ""
echo "Checking if Podman is installed..."
if command -v podman &> /dev/null; then
    PODMAN_VERSION=$(podman --version)
    echo "✓ $PODMAN_VERSION detected"
    echo ""
    echo "You're ready to build! Run: make build"
else
    echo "✗ Podman not found. Please install Podman first:"
    echo "  Ubuntu/Debian: sudo apt install podman"
    echo "  Visit: https://podman.io/"
fi
echo ""
