#!/bin/bash

# MCView Server - Load Images Script
# Loads Docker images from tar files for deployment on new machines

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

# Default backup file
BACKUP_FILE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            BACKUP_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -f, --file FILE        Backup tar file to load (required)"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 -f ./backups/mcview-images-20231201_143022.tar"
            echo "  $0 -f /path/to/mcview-backup.tar"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

print_header "MCView Docker Images Restore Tool"
echo ""

# Check if backup file is specified
if [ -z "$BACKUP_FILE" ]; then
    print_error "Backup file not specified!"
    echo "Usage: $0 -f <backup-file.tar>"
    echo "Use -h or --help for more information"
    exit 1
fi

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    print_error "Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible!"
    exit 1
fi

# Check if file is a valid tar file
if ! tar -tf "$BACKUP_FILE" >/dev/null 2>&1; then
    print_error "Invalid tar file: $BACKUP_FILE"
    exit 1
fi

# Get file size
FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
print_status "Loading backup file: $BACKUP_FILE (Size: $FILE_SIZE)"

# Check for manifest file
MANIFEST_FILE="${BACKUP_FILE%.tar}.manifest"
if [ -f "$MANIFEST_FILE" ]; then
    print_status "Found manifest file: $MANIFEST_FILE"
    echo ""
    print_status "Backup details:"
    cat "$MANIFEST_FILE"
    echo ""
else
    print_warning "No manifest file found. Proceeding with load..."
fi

# Check available disk space
REQUIRED_SPACE=$(du -k "$BACKUP_FILE" | cut -f1)
AVAILABLE_SPACE=$(df -k . | tail -1 | awk '{print $4}')

if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    print_error "Insufficient disk space!"
    print_status "Required: $(numfmt --to=iec-i --suffix=B $((REQUIRED_SPACE * 1024)))"
    print_status "Available: $(numfmt --to=iec-i --suffix=B $((AVAILABLE_SPACE * 1024)))"
    exit 1
fi

# Check for existing images that might conflict
print_status "Checking for existing images..."

EXISTING_IMAGES=()
if docker image inspect mcview-shiny:latest >/dev/null 2>&1; then
    EXISTING_IMAGES+=("mcview-shiny:latest")
fi

if docker image inspect nginx:alpine >/dev/null 2>&1; then
    EXISTING_IMAGES+=("nginx:alpine")
fi

if [ ${#EXISTING_IMAGES[@]} -gt 0 ]; then
    print_warning "The following images already exist and will be overwritten:"
    for img in "${EXISTING_IMAGES[@]}"; do
        echo "  - $img"
    done
    echo ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled."
        exit 0
    fi
fi

# Load images from tar file
print_status "Loading Docker images from backup file..."
echo "This may take several minutes depending on the size of the images..."

if docker load -i "$BACKUP_FILE"; then
    print_status "Images loaded successfully!"
    
    # Verify loaded images
    echo ""
    print_status "Verifying loaded images..."
    
    LOADED_IMAGES=()
    if docker image inspect mcview-shiny:latest >/dev/null 2>&1; then
        LOADED_IMAGES+=("mcview-shiny:latest")
        print_status "✓ mcview-shiny:latest loaded"
    else
        print_warning "✗ mcview-shiny:latest not found in backup"
    fi
    
    if docker image inspect nginx:alpine >/dev/null 2>&1; then
        LOADED_IMAGES+=("nginx:alpine")
        print_status "✓ nginx:alpine loaded"
    else
        print_warning "✗ nginx:alpine not found in backup"
    fi
    
    # Check for any other loaded images
    for img in $(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(mcview|shiny)"); do
        if [[ ! " ${LOADED_IMAGES[@]} " =~ " ${img} " ]]; then
            LOADED_IMAGES+=("$img")
            print_status "✓ $img loaded"
        fi
    done
    
    echo ""
    print_status "Restore completed successfully!"
    print_status "Loaded ${#LOADED_IMAGES[@]} image(s):"
    for img in "${LOADED_IMAGES[@]}"; do
        echo "  - $img"
    done
    
    echo ""
    print_status "Next step:"
    print_status "Run: ./scripts/start.sh"
    
else
    print_error "Failed to load images from backup file!"
    exit 1
fi
