#!/bin/bash

# MCView Server - Build Script
# Builds the Docker images for the MCView server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
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
    print_warning ".env file not found. Creating from .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        print_warning "Please edit .env file with your configuration before continuing."
        exit 1
    else
        print_error ".env.example file not found!"
        exit 1
    fi
fi

# Load environment variables
source .env

# Validate required variables
required_vars=(
    "MCVIEW_DATA_DIR"
    "MCVIEW_APPS_DIR" 
    "MCVIEW_LOGS_DIR"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        print_error "Required environment variable $var is not set in .env"
        exit 1
    fi
done

# Create required directories if they don't exist
print_status "Creating required directories..."
for dir in "$MCVIEW_DATA_DIR" "$MCVIEW_APPS_DIR" "$MCVIEW_LOGS_DIR"; do
    if [ ! -d "$dir" ]; then
        print_status "Creating directory: $dir"
        mkdir -p "$dir"
    fi
done

# Build the Docker images
print_status "Building MCView Docker images..."

# Build Shiny server image
print_status "Building Shiny server image..."
docker build \
    --build-arg GITHUB_PAT="${GITHUB_PAT:-}" \
    --build-arg MCVIEW_USER_UID="${MCVIEW_USER_UID:-1000}" \
    --build-arg MCVIEW_USER_GID="${MCVIEW_USER_GID:-1000}" \
    -t mcview-shiny:latest \
    ./shiny-server/

if [ $? -eq 0 ]; then
    print_status "Build completed successfully!"
    print_status "You can now run: ./scripts/start.sh"
else
    print_error "Build failed!"
    exit 1
fi

# Optional: Clean up unused Docker images
read -p "Clean up unused Docker images? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cleaning up unused Docker images..."
    docker image prune -f
fi

print_status "Build process complete!"
