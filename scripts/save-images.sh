#!/bin/bash

# MCView Server - Save Images Script
# Saves Docker images to tar files for backup/transfer

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

# Default backup directory
BACKUP_DIR=${MCVIEW_BACKUP_DIR:-./backups}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="mcview-images-${TIMESTAMP}.tar"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--directory)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -n|--name)
            BACKUP_NAME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -d, --directory DIR    Backup directory (default: ./backups)"
            echo "  -n, --name NAME        Backup filename (default: mcview-images-TIMESTAMP.tar)"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Save with default settings"
            echo "  $0 -d /path/to/backups               # Specify backup directory"
            echo "  $0 -n my-mcview-backup.tar           # Specify backup filename"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

print_header "MCView Docker Images Backup Tool"
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible!"
    exit 1
fi

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    print_status "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
fi

# Check if MCView images exist
print_status "Checking for MCView Docker images..."

IMAGES_TO_SAVE=()
if docker image inspect mcview-shiny:latest >/dev/null 2>&1; then
    IMAGES_TO_SAVE+=("mcview-shiny:latest")
    print_status "Found mcview-shiny:latest"
else
    print_warning "mcview-shiny:latest not found"
fi

if docker image inspect nginx:alpine >/dev/null 2>&1; then
    IMAGES_TO_SAVE+=("nginx:alpine")
    print_status "Found nginx:alpine"
else
    print_warning "nginx:alpine not found"
fi

# Check for any other related images
for img in $(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(mcview|shiny)"); do
    if [[ ! " ${IMAGES_TO_SAVE[@]} " =~ " ${img} " ]]; then
        IMAGES_TO_SAVE+=("$img")
        print_status "Found additional image: $img"
    fi
done

if [ ${#IMAGES_TO_SAVE[@]} -eq 0 ]; then
    print_error "No MCView Docker images found to backup!"
    print_status "Make sure to run ./scripts/build.sh first to build the images."
    exit 1
fi

# Save images to tar file
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
print_status "Saving ${#IMAGES_TO_SAVE[@]} image(s) to: $BACKUP_PATH"

# Show images being saved
echo ""
print_status "Images to be saved:"
for img in "${IMAGES_TO_SAVE[@]}"; do
    echo "  - $img"
done
echo ""

# Perform the save operation
if docker save -o "$BACKUP_PATH" "${IMAGES_TO_SAVE[@]}"; then
    print_status "Images saved successfully!"
    
    # Get file size
    FILE_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
    print_status "Backup file size: $FILE_SIZE"
    
    # Create a manifest file with image details
    MANIFEST_PATH="$BACKUP_DIR/${BACKUP_NAME%.tar}.manifest"
    print_status "Creating manifest file: $MANIFEST_PATH"
    
    cat > "$MANIFEST_PATH" << EOF
MCView Docker Images Backup Manifest
====================================
Created: $(date)
Backup File: $BACKUP_NAME
Total Size: $FILE_SIZE

Images Included:
$(for img in "${IMAGES_TO_SAVE[@]}"; do
    echo "- $img"
    docker images "$img" --format "  Size: {{.Size}}"
    docker images "$img" --format "  Created: {{.CreatedAt}}"
    echo ""
done)

Restore Command:
  ./scripts/load-images.sh -f $BACKUP_PATH

EOF
    
    print_status "Manifest created: $MANIFEST_PATH"
    
    echo ""
    print_status "Backup completed successfully!"
    print_status "To restore on another machine, copy these files:"
    print_status "  - $BACKUP_PATH"
    print_status "  - $MANIFEST_PATH"
    print_status ""
    print_status "Then run: ./scripts/load-images.sh -f $BACKUP_PATH"
    
else
    print_error "Failed to save images!"
    exit 1
fi
