#!/bin/bash

# ==============================
# Konfiguration
# ==============================
SERVER_DIR="/home/user/Desktop/maniaplanetserver"
EXPANSION_DIR="/home/user/Desktop/expansion"
ADMINPANEL_DIR="/home/user/Desktop/maniaplanetserver/adminpanel"

SERVER_BIN="./ManiaPlanetServer"

IP_FILE="/home/user/Desktop/maniaplanetserver/last_public_ip.txt"

PROCESS_NAME="ManiaPlanetServer"
NODE_PROCESS="node server.js"

# ==============================
# Force IP laden
# ==============================
if [ ! -f "$IP_FILE" ]; then
    echo "❌ Fehler: IP-Datei nicht gefunden: $IP_FILE"
    exit 1
fi

FORCE_IP_ADDRESS=$(cat "$IP_FILE")

if [ -z "$FORCE_IP_ADDRESS" ]; then
    echo "❌ Fehler: IP-Datei ist leer"
    exit 1
fi

# ==============================
# Server Args
# ==============================
SERVER_ARGS="/dedicated_cfg=dedicated_cfg.txt \
/title=TMStadium@nadeo \
/game_settings=/home/user/Desktop/maniaplanetserver/UserData/Maps/MatchSettings/maplist.txt \
/forceip=${FORCE_IP_ADDRESS}"

# ==============================
# Stop Node Adminpanel
# ==============================
echo "[0/5] Stopping node server.js..."
pkill -TERM -f "$NODE_PROCESS"

while pgrep -f "$NODE_PROCESS" >/dev/null; do
    echo "  → waiting for node server.js to stop..."
    sleep 1
done

echo "  ✔ node server.js stopped"

# ==============================
# Stop Server
# ==============================
echo "[1/5] Stopping ManiaPlanetServer..."

pkill -TERM -f "$PROCESS_NAME"

while pgrep -f "$PROCESS_NAME" >/dev/null; do
    echo "  → waiting for server to stop..."
    sleep 1
done

echo "  ✔ server stopped"
sleep 10
# ==============================
# Start Server
# ==============================
echo "[2/5] Starting ManiaPlanetServer..."
cd "$SERVER_DIR" || exit 1

$SERVER_BIN $SERVER_ARGS &

until pgrep -f "$PROCESS_NAME" >/dev/null; do
    echo "  → waiting for server to start..."
    sleep 1
done

echo "  ✔ server running"

sleep 5

# ==============================
# Start Node Adminpanel
# ==============================
echo "[3/5] Starting node server.js..."
cd "$ADMINPANEL_DIR" || exit 1
nohup node server.js > adminpanel.log 2>&1 &

echo "  ✔ node server.js running"

# ==============================
# Expansion stoppen
# ==============================
echo "[4/5] Stopping expansion..."
cd "$EXPANSION_DIR" || exit 1
./run --stop

sleep 10

# ==============================
# Expansion starten
# ==============================
echo "[5/5] Starting expansion..."
./run --start

echo "✔ Restart complete"
