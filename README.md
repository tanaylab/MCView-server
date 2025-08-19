# MCView Server

A containerized deployment of MCView (MetaCell Viewer).

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/tanaylab/MCView-server.git
cd MCView-server

# 2. Configure your environment
cp .env.example .env
# Edit .env with your paths and settings

# 3. Build and start the server
./scripts/build.sh
./scripts/start.sh

# 4. Access the server
open http://localhost
```

## Requirements

- **Docker** (version 20.0 or higher)
- **Docker Compose** (version 1.28 or higher)
- **Minimum 16GB RAM** (64GB+ recommended)

## Installation

### 1. System Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install docker.io docker compose git
sudo usermod -aG docker $USER
# Log out and back in for group changes
```

**CentOS/RHEL:**
```bash
sudo yum install docker docker compose git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

### 2. Clone and Setup

```bash
git clone https://github.com/tanaylab/MCView-server.git
cd MCView-server
cp .env.example .env
```

### 3. Configure Environment

Edit the `.env` file with your specific paths:

```bash
# Example configuration
MCVIEW_DATA_DIR=/opt/mcview/data
MCVIEW_APPS_DIR=/opt/mcview/apps
MCVIEW_LOGS_DIR=/var/log/mcview
MCVIEW_STATIC_DIR=/opt/mcview/static

MCVIEW_USER_UID=1000
MCVIEW_USER_GID=1000
```

**Important**: Use absolute paths and ensure the user has read/write permissions.

### 4. Create Directory Structure

```bash
source .env
# Create all required directories
mkdir -p $MCVIEW_DATA_DIR
mkdir -p $MCVIEW_APPS_DIR
mkdir -p $MCVIEW_LOGS_DIR
mkdir -p $MCVIEW_STATIC_DIR

# Set proper permissions
sudo chown -R $MCVIEW_USER_UID:$MCVIEW_USER_GID $MCVIEW_DATA_DIR $MCVIEW_APPS_DIR $MCVIEW_LOGS_DIR $MCVIEW_STATIC_DIR
```

### 5. Build and Start

```bash
./scripts/build.sh
./scripts/start.sh
```

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `MCVIEW_PORT` | External web port | 80 | No |
| `MCVIEW_SSL_PORT` | SSL port for HTTPS | 443 | No |
| `MCVIEW_SHINY_PORT` | Internal Shiny port | 3838 | No |
| `MCVIEW_DATA_DIR` | Main data directory | - | Yes |
| `MCVIEW_APPS_DIR` | Shiny applications | - | Yes |
| `MCVIEW_LOGS_DIR` | Log files | - | Yes |
| `MCVIEW_STATIC_DIR` | Static files directory | ./static | No |
| `MCVIEW_SSL_CERTS` | SSL certificates directory | ./ssl | No |
| `MCVIEW_USER_UID` | User ID | 1000 | No |
| `MCVIEW_USER_GID` | Group ID | 1000 | No |
| `GITHUB_PAT` | GitHub Personal Access Token | - | No |
| `SHINY_LOG_LEVEL` | Shiny server log level | INFO | No |

### Custom R Packages

To install additional R packages:

1. **During build** (recommended):
   ```dockerfile
   # Add to Dockerfile
   RUN Rscript -e 'install.packages("your_package")'
   ```

2. **Runtime installation**:
   ```bash
   docker exec mcview-server-shiny-1 R -e 'install.packages("your_package")'
   ./scripts/restart.sh
   ```

## Usage

### Basic Operations

```bash
# Start the server
./scripts/start.sh

# Stop the server
./scripts/stop.sh

# View logs
./scripts/logs.sh

# Restart services
./scripts/restart.sh

# Rebuild images
./scripts/build.sh

# Save images 
./scripts/save_images.sh

# Load images
./scripts/load_images.sh -f backups/mcview-images-(date).tar.gz
```

### Accessing the Server

- **Web Interface**: http://localhost 
- **Direct Shiny Access**: http://localhost:3838

### Deploying Shiny Applications

1. **Place apps in the apps directory**:
   ```bash
   cp -r my-mcview-app $MCVIEW_APPS_DIR/
   ```

2. **Restart specific app**:
   ```bash
   touch $MCVIEW_APPS_DIR/my-mcview-app/restart.txt
   ```

### Managing Data

**Backup Strategy**:
```bash
# Backup data and apps
tar -czf backups/mcview-backup-$(date +%Y%m%d).tar.gz \
  $MCVIEW_DATA_DIR $MCVIEW_APPS_DIR $MCVIEW_LOGS_DIR

# Backup configuration
mkdir -p backups/config-backup-$(date +%Y%m%d)
cp .env config/ backups/config-backup-$(date +%Y%m%d)/

# Save images 
./scripts/save_images.sh

# Load images
./scripts/load_images.sh -f backups/mcview-images-(date).tar.gz
```

## Troubleshooting

### Common Issues

**1. Permission Denied Errors**
```bash
# Check and fix ownership
sudo chown -R $MCVIEW_USER_UID:$MCVIEW_USER_GID $MCVIEW_DATA_DIR $MCVIEW_APPS_DIR $MCVIEW_LOGS_DIR $MCVIEW_STATIC_DIR
```

**2. Port Already in Use**
```bash
# Check what's using the port
sudo netstat -tulpn | grep :80
# Change MCVIEW_PORT in .env
```

**3. Out of Memory**
```bash
# Check Docker resources
docker system df
docker system prune  # Clean unused resources
```

**4. Shiny Apps Not Loading**
```bash
source .env

# Check app logs
./scripts/view-latest-app-log.sh app-name

# Restart specific app
touch $MCVIEW_APPS_DIR/app-name/restart.txt
```

### Logs

```bash
# View all service logs
./scripts/logs.sh

# Shiny-specific logs
ls $MCVIEW_LOGS_DIR/

# View latest app log
./scripts/view-latest-app-log.sh app-name

# Nginx logs
docker exec mcview-server-nginx-1 cat /var/log/nginx/error.log
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
