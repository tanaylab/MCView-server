#!/bin/bash

export SHINY_LOG_LEVEL=${SHINY_LOG_LEVEL:-INFO}

# Ensure proper ownership of key directories
# chown -R shiny:shiny /var/log/shiny-server || true
# chown -R shiny:shiny /srv/shiny-server || true

# Start shiny server
exec shiny-server --pidfile=/var/run/shiny-server.pid
