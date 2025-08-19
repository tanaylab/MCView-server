#!/bin/bash

# Script to view the latest log file for a specific app
# Usage: ./view-latest-app-log.sh <app-name> [logs-directory]

# Check if app name is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 <app-name> [logs-directory]"
    echo "  app-name: Required - name pattern to search for in log files"
    echo "  logs-directory: Optional - directory to search (defaults to \$MCVIEW_LOGS_DIR)"
    exit 1
fi

APP_NAME="$1"


if [[ -e .env ]]; then
    source .env
fi

# Use provided directory or fall back to environment variable
LOGS_DIR="${2:-$MCVIEW_LOGS_DIR}"

# Check if logs directory is set
if [[ -z "$LOGS_DIR" ]]; then
    echo "Error: No logs directory specified and MCVIEW_LOGS_DIR environment variable is not set"
    echo "Usage: $0 <app-name> [logs-directory]"
    exit 1
fi

# Check if the directory exists
if [[ ! -d "$LOGS_DIR" ]]; then
    echo "Error: Directory $LOGS_DIR does not exist"
    exit 1
fi

# Find and display the latest log file
echo "Looking for latest log file containing '$APP_NAME' in $LOGS_DIR..."

LATEST_LOG=$(find "$LOGS_DIR" -name "*$APP_NAME*" -type f -exec ls -lt {} + | head -n 1 | awk '{print $9}')

if [[ -z "$LATEST_LOG" ]]; then
    echo "No log files found containing '$APP_NAME'"
    exit 1
fi

echo "Found: $LATEST_LOG"
echo "----------------------------------------"

# Display the log content
find "$LOGS_DIR" -name "*$APP_NAME*" -type f -exec ls -lt {} + | head -n 1 | awk '{print $9}' | xargs cat