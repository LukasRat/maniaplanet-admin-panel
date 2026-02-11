#!/bin/bash
#
# ManiaPlanet Server Restart Script
# This script attempts to restart the ManiaPlanet dedicated server
#
# IMPORTANT: This script needs to be configured for your specific server setup!
# By default, it will NOT restart anything - you must uncomment and configure
# one of the methods below that matches your server installation.
#
# Usage: ./restart.sh
#

echo "========================================"
echo "ManiaPlanet Server Restart Script"
echo "Started at: $(date)"
echo "========================================"

# ============================================================================
# METHOD 1: SYSTEMD SERVICE (Most common for modern Linux)
# ============================================================================
# If your ManiaPlanet server runs as a systemd service, uncomment ONE of these:
#
# sudo systemctl restart maniaplanet-server
# sudo systemctl restart trackmania-server
#
# Note: You may need to configure sudo to allow this without password

# ============================================================================
# METHOD 2: INIT.D SERVICE (Older Linux systems)
# ============================================================================
# If your server uses init.d, uncomment ONE of these:
#
# sudo service maniaplanet-server restart
# sudo service trackmania-server restart

# ============================================================================
# METHOD 3: DIRECT PROCESS RESTART (If you have a PID file)
# ============================================================================
# If you know where your server's PID file is located, uncomment and modify:
#
# PID_FILE="/path/to/your/server.pid"
# if [ -f "$PID_FILE" ]; then
#     PID=$(cat "$PID_FILE")
#     if kill -0 "$PID" 2>/dev/null; then
#         echo "Stopping server process $PID..."
#         kill -TERM "$PID"
#         sleep 3
#         if kill -0 "$PID" 2>/dev/null; then
#             echo "Force killing process..."
#             kill -9 "$PID"
#         fi
#         echo "Starting server again..."
#         # Add your server start command here:
#         # /path/to/ManiaPlanetServer /dedicated_cfg=your_config.txt &
#         echo "Server restarted successfully"
#         exit 0
#     fi
# fi

# ============================================================================
# METHOD 4: SCREEN/TMUX SESSION RESTART
# ============================================================================
# If your server runs in a screen or tmux session:
#
# SCREEN_NAME="maniaplanet"
# screen -S "$SCREEN_NAME" -X quit
# sleep 2
# screen -dmS "$SCREEN_NAME" /path/to/ManiaPlanetServer /dedicated_cfg=your_config.txt
# echo "Server restarted in screen session: $SCREEN_NAME"
# exit 0

# ============================================================================
# METHOD 5: DOCKER CONTAINER RESTART
# ============================================================================
# If your server runs in Docker:
#
# CONTAINER_NAME="maniaplanet-server"
# docker restart "$CONTAINER_NAME"
# echo "Docker container $CONTAINER_NAME restarted"
# exit 0

# ============================================================================
# METHOD 6: CUSTOM COMMAND (Your specific setup)
# ============================================================================
# Add your custom restart command here. For example:
#
# /opt/maniaplanet/restart_server.sh
# exit 0

# ============================================================================
# ERROR: NO METHOD CONFIGURED
# ============================================================================
echo ""
echo "ERROR: No restart method configured!"
echo ""
echo "This script needs to be customized for your server setup."
echo "Please edit restart.sh and uncomment/configure one of the methods above."
echo ""
echo "Common configurations:"
echo "  - Systemd service: uncomment line with 'systemctl restart'"
echo "  - Screen/tmux: uncomment and configure screen session method"
echo "  - Docker: uncomment and configure docker restart method"
echo "  - Custom script: add your restart command in Method 6"
echo ""
echo "After configuring, test manually with: ./restart.sh"
echo ""
exit 1
