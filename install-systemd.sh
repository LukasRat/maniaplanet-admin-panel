#!/bin/bash

# ManiaPlanet Admin Panel - Quick Installation Script for systemd Service
# This script helps you quickly set up the admin panel as a systemd service

set -e

echo "=================================="
echo "ManiaPlanet Admin Panel Installer"
echo "=================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run this script as root"
    echo "The script will ask for sudo password when needed"
    exit 1
fi

# Check if systemd is available
if ! command -v systemctl &> /dev/null; then
    echo "❌ systemd is not available on this system"
    echo "Please use PM2 or Docker instead"
    exit 1
fi

# Default values
DEFAULT_INSTALL_DIR="/opt/maniaplanet-admin-panel"
DEFAULT_USER="maniaplanet"
DEFAULT_MAPS_DIR=""

# Ask for installation directory
read -p "Installation directory [$DEFAULT_INSTALL_DIR]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}

# Ask for user
read -p "Run as user [$DEFAULT_USER]: " SERVICE_USER
SERVICE_USER=${SERVICE_USER:-$DEFAULT_USER}

# Ask for maps directory
echo ""
echo "⚠️  IMPORTANT: Enter the full path to your ManiaPlanet server's UserData/Maps directory"
echo "Example: /home/user/maniaplanetserver/UserData/Maps"
read -p "Maps directory path: " MAPS_DIR

if [ -z "$MAPS_DIR" ]; then
    echo "❌ Maps directory path is required"
    exit 1
fi

# Confirm settings
echo ""
echo "Installation settings:"
echo "  Install directory: $INSTALL_DIR"
echo "  Service user: $SERVICE_USER"
echo "  Maps directory: $MAPS_DIR"
echo ""
read -p "Proceed with installation? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Installation cancelled"
    exit 0
fi

echo ""
echo "Starting installation..."

# Create user if it doesn't exist
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "Creating user $SERVICE_USER..."
    sudo useradd -r -s /bin/false "$SERVICE_USER"
fi

# Create installation directory
echo "Creating installation directory..."
sudo mkdir -p "$INSTALL_DIR"

# Copy files
echo "Copying application files..."
sudo cp -r ./* "$INSTALL_DIR/"
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"

# Install dependencies
echo "Installing dependencies..."
cd "$INSTALL_DIR"
sudo -u "$SERVICE_USER" npm install --production

# Create systemd service file
echo "Creating systemd service file..."
sudo tee /etc/systemd/system/maniaplanet-admin-panel.service > /dev/null <<EOF
[Unit]
Description=ManiaPlanet Admin Panel
Documentation=https://github.com/LukasRat/maniaplanet-admin-panel
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=maniaplanet-admin-panel

# Environment variables
Environment=NODE_ENV=production
Environment=MANIAPLANET_MAPS_DIR=$MAPS_DIR

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR $MAPS_DIR

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
echo "Reloading systemd..."
sudo systemctl daemon-reload

# Start and enable service
echo "Starting service..."
sudo systemctl start maniaplanet-admin-panel
sudo systemctl enable maniaplanet-admin-panel

# Check status
echo ""
echo "✅ Installation complete!"
echo ""
echo "Service status:"
sudo systemctl status maniaplanet-admin-panel --no-pager

echo ""
echo "Useful commands:"
echo "  View logs:    sudo journalctl -u maniaplanet-admin-panel -f"
echo "  Restart:      sudo systemctl restart maniaplanet-admin-panel"
echo "  Stop:         sudo systemctl stop maniaplanet-admin-panel"
echo "  Status:       sudo systemctl status maniaplanet-admin-panel"
echo ""
echo "Access the admin panel at: http://localhost:3100"
