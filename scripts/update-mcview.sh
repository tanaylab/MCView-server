#!/bin/bash

# MCView Server - Update MCView Script
# Updates the MCView R package inside the running shiny container,
# commits a dated image snapshot, retags mcview-shiny:latest, and
# triggers app restarts by touching restart.txt files.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
	echo -e "${BLUE}[HEADER]${NC} $1"
}

print_header "MCView Update Tool"
echo ""

# Ensure Docker is available
if ! docker info >/dev/null 2>&1; then
	print_error "Docker is not running or not accessible!"
	exit 1
fi

# Load environment variables if present (for GITHUB_PAT, etc.)
if [ -f .env ]; then
	# shellcheck disable=SC1091
	source .env
fi

# Resolve the running shiny container ID via docker compose service name
print_status "Locating running shiny container..."
container_id=$(docker compose ps -q shiny || true)

if [ -z "$container_id" ]; then
	print_warning "No container found via 'docker compose ps -q shiny'. Checking running containers..."
	# Fallback: find a running container derived from mcview-shiny:latest
	container_id=$(docker ps -qf "ancestor=mcview-shiny:latest" | head -n1 || true)
fi

if [ -z "$container_id" ]; then
	print_error "Shiny container not found. Ensure the server is running (./scripts/start.sh)."
	exit 1
fi

print_status "Using container: $container_id"

# Update MCView package inside the container
print_header "Installing latest MCView from GitHub inside the container"
if [ -n "$GITHUB_PAT" ]; then
	print_status "Using GITHUB_PAT from environment"
fi

docker exec -e GITHUB_PAT="$GITHUB_PAT" "$container_id" R -e 'remotes::install_github("tanaylab/MCView")'

print_status "MCView package updated successfully in the running container."

# Commit container to a dated image and retag latest
current_date=$(date +'%Y%m%d_%H%M%S')
new_tag="mcview-shiny:fixed-$current_date"

print_header "Creating image snapshot: $new_tag"
docker commit "$container_id" "$new_tag" >/dev/null
print_status "Snapshot created: $new_tag"

print_status "Retagging $new_tag as mcview-shiny:latest"
docker tag "$new_tag" mcview-shiny:latest

# Trigger app restarts by touching restart.txt markers
print_header "Triggering app restarts via restart.txt"
docker exec "$container_id" find /srv/shiny-server/apps -name "restart.txt" -type f -exec touch {} \; || print_warning "No restart.txt files found to touch."

echo ""
print_status "Update completed."
print_status "Snapshot image: $new_tag"
print_status "Current latest: mcview-shiny:latest"
echo ""
print_status "Next steps:"
print_status "- Optionally back up images: ./scripts/save-images.sh"
print_status "- If you want containers to be recreated from the new image, run: ./scripts/restart.sh"


