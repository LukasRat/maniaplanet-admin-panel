#!/bin/bash
# Helper script to show the exact URL to access the ManiaPlanet Admin Panel
# Usage: ./show-access-url.sh [port]

PORT=${1:-3200}

echo "================================================"
echo "ManiaPlanet Admin Panel - Access URL Helper"
echo "================================================"
echo ""

# Check if container is running
if ! docker ps | grep -q maniaplanet-admin-panel; then
    echo "⚠️  WARNING: Container is not running!"
    echo ""
    echo "Start the container first:"
    echo "  docker-compose up -d"
    echo ""
    exit 1
fi

# Get the actual port from Docker
ACTUAL_PORT=$(docker ps --format "{{.Ports}}" | grep maniaplanet | grep -oP '0.0.0.0:\K[0-9]+' | head -1)

if [ -n "$ACTUAL_PORT" ]; then
    PORT=$ACTUAL_PORT
    echo "✓ Container is running on port $PORT"
else
    echo "⚠️  Could not detect port from container"
    echo "   Using port $PORT from argument/default"
fi
echo ""

# Get host IP addresses
echo "Your Host IP Addresses:"
echo "─────────────────────────────────────"

if command -v hostname &> /dev/null; then
    IPS=$(hostname -I 2>/dev/null)
    if [ -n "$IPS" ]; then
        PRIMARY_IP=$(echo $IPS | awk '{print $1}')
        for ip in $IPS; do
            if [ "$ip" = "$PRIMARY_IP" ]; then
                echo "  $ip  (primary)"
            else
                echo "  $ip"
            fi
        done
    fi
fi

if [ -z "$PRIMARY_IP" ] && command -v ip &> /dev/null; then
    PRIMARY_IP=$(ip addr show | grep "inet " | grep -v "127.0.0.1" | head -1 | awk '{print $2}' | cut -d/ -f1)
    echo "  $PRIMARY_IP  (detected)"
fi

if [ -z "$PRIMARY_IP" ]; then
    PRIMARY_IP="YOUR_IP_HERE"
    echo "  (Unable to detect IP automatically)"
fi

echo ""
echo "Access URLs:"
echo "─────────────────────────────────────"
echo ""
echo "📍 From the SAME computer (where Docker is running):"
echo "   http://localhost:$PORT/"
echo ""
echo "🌐 From ANOTHER computer on your network:"
echo "   http://$PRIMARY_IP:$PORT/"
echo ""
echo "─────────────────────────────────────"
echo ""

# Check if port is accessible locally
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT 2>&1)
    if echo "$HTTP_CODE" | grep -q "200\|302"; then
        echo "✓ Local access test successful (HTTP $HTTP_CODE)"
        echo "  The admin panel is responding correctly"
    else
        echo "⚠️  Local access test failed"
        if echo "$HTTP_CODE" | grep -q "000"; then
            echo "  Error: Connection Refused"
            echo ""
            echo "  This usually means:"
            echo "  1. Container is running but application crashed"
            echo "  2. Application failed to start"
            echo "  3. Application listening on wrong interface"
            echo ""
            echo "  Diagnostic steps:"
            echo "  ─────────────────────────────────────"
            echo "  # 1. Check container logs:"
            echo "  docker logs --tail 50 maniaplanet-admin-panel"
            echo ""
            echo "  # 2. Check if container is restarting:"
            echo "  docker ps -a | grep maniaplanet"
            echo ""
            echo "  # 3. Check application status inside container:"
            echo "  docker exec maniaplanet-admin-panel ps aux | grep node"
            echo ""
            echo "  # 4. See detailed troubleshooting:"
            echo "  cat CONNECTION-REFUSED.md"
            echo ""
        else
            echo "  HTTP Code: $HTTP_CODE"
            echo "  Check container logs: docker logs maniaplanet-admin-panel"
        fi
    fi
    echo ""
fi

# Provide copy-paste ready commands
echo "Quick Test Commands:"
echo "─────────────────────────────────────"
echo "# Test from this machine:"
echo "curl http://localhost:$PORT"
echo ""
echo "# Test from another machine on your network:"
echo "curl http://$PRIMARY_IP:$PORT"
echo ""

# Check firewall
echo "Firewall Check:"
echo "─────────────────────────────────────"
if command -v ufw &> /dev/null; then
    if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
        if sudo ufw status 2>/dev/null | grep -q "$PORT"; then
            echo "✓ Port $PORT is allowed in UFW firewall"
        else
            echo "⚠️  Port $PORT is NOT in UFW firewall rules"
            echo "   Add it with: sudo ufw allow $PORT/tcp"
        fi
    else
        echo "ℹ️  UFW firewall is not active"
    fi
elif command -v firewall-cmd &> /dev/null; then
    if sudo firewall-cmd --state 2>/dev/null | grep -q "running"; then
        if sudo firewall-cmd --list-ports 2>/dev/null | grep -q "$PORT"; then
            echo "✓ Port $PORT is allowed in firewalld"
        else
            echo "⚠️  Port $PORT is NOT in firewalld rules"
            echo "   Add it with: sudo firewall-cmd --add-port=$PORT/tcp --permanent && sudo firewall-cmd --reload"
        fi
    else
        echo "ℹ️  firewalld is not running"
    fi
else
    echo "ℹ️  No firewall detected (ufw/firewalld)"
fi

echo ""
echo "================================================"
echo "IMPORTANT: Use HOST IP, NOT container IP!"
echo "See WHICH-IP.md for detailed explanation"
echo "================================================"
