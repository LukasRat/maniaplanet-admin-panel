#!/bin/bash

# ==============================
# Konfiguration
# ==============================
EXPANSION_DIR="/home/user/Desktop/expansion"

# ==============================
# Expansion stoppen
# ==============================
echo "[1/2] Stopping expansion..."
cd "$EXPANSION_DIR" || {
    echo "❌ Fehler: Expansion-Verzeichnis nicht gefunden: $EXPANSION_DIR"
    exit 1
}

./run --stop

sleep 10

# ==============================
# Expansion starten
# ==============================
echo "[2/2] Starting expansion..."
./run --start

echo "✔ Expansion restart complete"
