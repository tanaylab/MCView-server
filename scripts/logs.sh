#!/bin/bash

# MCView Server - Logs Script
# Shows logs from all MCView services

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if services are running
if ! docker compose ps | grep -q "Up"; then
    print_warning "MCView services don't appear to be running."
    print_warning "Start them with: ./scripts/start.sh"
fi

# Default to following logs, but allow options
FOLLOW_LOGS=true
SERVICE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-follow|-n)
            FOLLOW_LOGS=false
            shift
            ;;
        --service|-s)
            SERVICE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --no-follow, -n    Don't follow logs (show and exit)"
            echo "  --service, -s      Show logs for specific service (nginx|shiny)"
            echo "  --help, -h         Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Show logs
if [ "$FOLLOW_LOGS" = true ]; then
    if [ -n "$SERVICE" ]; then
        print_status "Following logs for service: $SERVICE"
        docker compose logs -f "$SERVICE"
    else
        print_status "Following logs for all services (Ctrl+C to exit)"
        docker compose logs -f
    fi
else
    if [ -n "$SERVICE" ]; then
        print_status "Showing recent logs for service: $SERVICE"
        docker compose logs --tail=50 "$SERVICE"
    else
        print_status "Showing recent logs for all services"
        docker compose logs --tail=50
    fi
fi
