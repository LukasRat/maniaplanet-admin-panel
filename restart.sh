#!/bin/bash
#
# ManiaPlanet Server Restart Script
# This script attempts to restart the ManiaPlanet dedicated server
#
# Usage: ./restart.sh
#

echo "ManiaPlanet Server Restart initiated at $(date)"

# Method 1: Try systemctl (for systemd-managed servers)
if command -v systemctl &> /dev/null; then
    echo "Attempting restart via systemctl..."
    if systemctl restart maniaplanet-server 2>/dev/null; then
        echo "Server restarted successfully via systemctl"
        exit 0
    fi
    if systemctl restart trackmania-server 2>/dev/null; then
        echo "Server restarted successfully via systemctl"
        exit 0
    fi
fi

# Method 2: Try service command (for init.d systems)
if command -v service &> /dev/null; then
    echo "Attempting restart via service command..."
    if service maniaplanet-server restart 2>/dev/null; then
        echo "Server restarted successfully via service"
        exit 0
    fi
    if service trackmania-server restart 2>/dev/null; then
        echo "Server restarted successfully via service"
        exit 0
    fi
fi

# Method 3: Look for PID file and restart manually
POSSIBLE_PID_FILES=(
    "/var/run/maniaplanet-server.pid"
    "/var/run/trackmania-server.pid"
    "/tmp/maniaplanet-server.pid"
    "./server.pid"
)

for PID_FILE in "${POSSIBLE_PID_FILES[@]}"; do
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "Found server process with PID $PID, restarting..."
            kill -HUP "$PID" 2>/dev/null || kill -TERM "$PID" 2>/dev/null
            sleep 2
            echo "Server restart signal sent"
            exit 0
        fi
    fi
done

# Method 4: Custom restart command (to be configured by user)
# Uncomment and modify the line below with your specific restart command
# /path/to/your/restart/command

echo "WARNING: Could not automatically restart the server."
echo "Please configure this script with your specific server restart method."
echo "Edit restart.sh and add your custom restart command in Method 4."
exit 1
