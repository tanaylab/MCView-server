#!/bin/bash

# MCView Server - Restart Script
# Restarts the MCView server services

set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_status "Restarting MCView server..."

# Stop services
./scripts/stop.sh && sleep 3 && ./scripts/start.sh

print_status "MCView server restarted successfully!"
