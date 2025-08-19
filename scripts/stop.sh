#!/bin/bash

# MCView Server - Stop Script
# Stops the MCView server services

set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_status "Stopping MCView server..."
docker compose down

print_status "MCView server stopped successfully!"
print_status ""
print_status "To start again: ./scripts/start.sh"
