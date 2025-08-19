#!/bin/bash

# MCView Server - Start Script
# Starts the MCView server services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found! Please run ./scripts/build.sh first."
    exit 1
fi

# Load environment variables
source .env

# Check if Docker images exist
if ! docker image inspect mcview-shiny:latest >/dev/null 2>&1; then
    print_error "MCView Docker image not found! Please run ./scripts/build.sh first."
    exit 1
fi

# Start services
print_status "Starting MCView server..."
docker compose up -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 10

# Check service health
print_status "Checking service health..."

# Check if containers are running
if docker compose ps | grep -q "Up"; then
    print_status "Containers are running!"
else
    print_error "Some containers failed to start. Check logs with: ./scripts/logs.sh"
    exit 1
fi

# Test HTTP connectivity
MCVIEW_PORT=${MCVIEW_PORT:-80}
if curl -sf "http://localhost:$MCVIEW_PORT" >/dev/null 2>&1; then
    print_status "MCView server is accessible at http://localhost:$MCVIEW_PORT"
elif curl -sf "http://localhost:3838" >/dev/null 2>&1; then
    print_status "Shiny server is running at http://localhost:3838"
    print_warning "Nginx proxy may not be working. Check configuration."
else
    print_warning "Services are starting but not yet accessible. This may take a few more moments."
fi

print_status "MCView server startup complete!"
print_status ""
print_status "Access URLs:"
print_status "  Main interface: http://localhost:$MCVIEW_PORT"
print_status "  Direct Shiny:   http://localhost:3838"
print_status ""
print_status "Useful commands:"
print_status "  View logs:      ./scripts/logs.sh"
print_status "  Stop server:    ./scripts/stop.sh"
print_status "  Server status:  docker compose ps"
