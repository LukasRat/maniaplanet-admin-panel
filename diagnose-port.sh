#!/bin/bash
# Diagnostic script for ManiaPlanet Admin Panel port accessibility issues
# Usage: ./diagnose-port.sh [port_number]
# Example: ./diagnose-port.sh 3200

echo "================================================"
echo "ManiaPlanet Admin Panel - Port Diagnostic Tool"
echo "================================================"
echo ""

# Get port from argument or default to 3200
PORT=${1:-3200}
echo "Checking port: $PORT"
echo ""

# Check if .env file exists
echo "1. Checking .env file..."
if [ -f .env ]; then
    echo "   ✓ .env file found"
    echo "   Contents:"
    grep -E "HTTP_PORT|HTTP_HOST" .env | sed 's/^/     /'
    
    # Check if HTTP_PORT is set correctly
    if grep -q "HTTP_PORT=$PORT" .env; then
        echo "   ✓ HTTP_PORT is set to $PORT"
    else
        echo "   ✗ WARNING: HTTP_PORT is NOT set to $PORT in .env"
        echo "     Current value: $(grep HTTP_PORT .env)"
    fi
    
    # Check HTTP_HOST
    if grep -q "HTTP_HOST=0.0.0.0" .env; then
        echo "   ✓ HTTP_HOST is correctly set to 0.0.0.0"
    else
        echo "   ✗ WARNING: HTTP_HOST might not allow external access"
        echo "     Current value: $(grep HTTP_HOST .env)"
    fi
else
    echo "   ✗ ERROR: .env file not found!"
    echo "     Run: cp .env.example .env"
    exit 1
fi
echo ""

# Check if container is running
echo "2. Checking if container is running..."
CONTAINER_STATUS=$(docker ps -a --format "{{.Names}}\t{{.Status}}" | grep maniaplanet-admin-panel)
if docker ps | grep -q maniaplanet-admin-panel; then
    echo "   ✓ Container 'maniaplanet-admin-panel' is running"
    # Check if it's been restarting
    if echo "$CONTAINER_STATUS" | grep -qi "restarting"; then
        echo "   ⚠ WARNING: Container is in restart loop!"
        echo "     This means the application is crashing"
        echo "     Check logs: docker logs maniaplanet-admin-panel"
    fi
else
    if docker ps -a | grep -q maniaplanet-admin-panel; then
        echo "   ✗ ERROR: Container exists but is not running!"
        echo "     Status: $CONTAINER_STATUS"
        echo "     Check logs: docker logs maniaplanet-admin-panel"
        echo "     Try: docker-compose down && docker-compose up -d"
    else
        echo "   ✗ ERROR: Container is not running!"
        echo "     Run: docker-compose up -d"
    fi
    exit 1
fi
echo ""

# Check port mapping
echo "3. Checking Docker port mapping..."
PORT_MAP=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep maniaplanet-admin-panel | awk '{print $2}')
if echo "$PORT_MAP" | grep -q "$PORT"; then
    echo "   ✓ Port $PORT is mapped: $PORT_MAP"
else
    echo "   ✗ ERROR: Port $PORT is NOT mapped correctly!"
    echo "     Current mapping: $PORT_MAP"
    echo ""
    echo "   Quick fix:"
    echo "     docker-compose down && docker-compose up -d"
    echo ""
    echo "   If that doesn't work (persistent issue):"
    echo "     ./reset-port.sh $PORT"
    echo ""
    echo "   Or see: PERSISTENT-PORT-ISSUE.md"
    exit 1
fi
echo ""

# Check container logs
echo "4. Checking container logs..."
LOG_PORT=$(docker logs maniaplanet-admin-panel 2>&1 | grep -E "localhost:|0.0.0.0:" | tail -1)
if echo "$LOG_PORT" | grep -q ":$PORT"; then
    echo "   ✓ Application is listening on port $PORT"
    echo "     $LOG_PORT"
else
    echo "   ✗ WARNING: Application might not be on correct port"
    echo "     $LOG_PORT"
fi
echo ""

# Check if port is listening on host
echo "5. Checking if port is listening on host..."
if command -v netstat &> /dev/null; then
    if netstat -tuln | grep -q ":$PORT "; then
        echo "   ✓ Port $PORT is listening on host"
        netstat -tuln | grep ":$PORT " | sed 's/^/     /'
    else
        echo "   ✗ WARNING: Port $PORT is not listening on host"
    fi
elif command -v ss &> /dev/null; then
    if ss -tuln | grep -q ":$PORT "; then
        echo "   ✓ Port $PORT is listening on host"
        ss -tuln | grep ":$PORT " | sed 's/^/     /'
    else
        echo "   ✗ WARNING: Port $PORT is not listening on host"
    fi
else
    echo "   ⚠ Cannot check (netstat/ss not available)"
fi
echo ""

# Test local access
echo "6. Testing local access..."
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT 2>&1)
    if echo "$HTTP_CODE" | grep -q "200\|302"; then
        echo "   ✓ Local access works (HTTP $HTTP_CODE)"
    else
        if echo "$HTTP_CODE" | grep -q "000"; then
            echo "   ✗ Connection Refused (HTTP 000)"
            echo "     Application is not responding inside container"
            echo ""
            echo "   Possible causes:"
            echo "     1. Application crashed/failed to start"
            echo "     2. Application listening on 127.0.0.1 instead of 0.0.0.0"
            echo "     3. Port conflict inside container"
            echo ""
            echo "   Quick diagnostic:"
            echo "     docker logs --tail 30 maniaplanet-admin-panel"
            echo ""
            echo "   See: CONNECTION-REFUSED.md for detailed troubleshooting"
        else
            echo "   ✗ Local access failed (HTTP $HTTP_CODE)"
        fi
    fi
else
    echo "   ⚠ Cannot test (curl not available)"
fi
echo ""

# Get host IP addresses
echo "7. Checking network interfaces..."
if command -v ip &> /dev/null; then
    echo "   Host IP addresses:"
    ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print "     " $2}'
elif command -v ifconfig &> /dev/null; then
    echo "   Host IP addresses:"
    ifconfig | grep "inet " | grep -v "127.0.0.1" | awk '{print "     " $2}'
else
    echo "   ⚠ Cannot determine (ip/ifconfig not available)"
fi
echo ""

# Check Docker network mode
echo "8. Checking Docker network configuration..."
NETWORK_MODE=$(docker inspect maniaplanet-admin-panel --format '{{.HostConfig.NetworkMode}}')
echo "   Network mode: $NETWORK_MODE"
if [ "$NETWORK_MODE" = "host" ]; then
    echo "   ⚠ WARNING: Using host network mode"
    echo "     This might prevent external access on some systems"
    echo "     Consider using bridge mode (default in docker-compose.yml)"
else
    echo "   ✓ Using bridge/custom network (recommended)"
fi
echo ""

# Check firewall (if available)
echo "9. Checking firewall status..."
if command -v ufw &> /dev/null; then
    if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
        echo "   UFW firewall is active"
        if sudo ufw status 2>/dev/null | grep -q "$PORT"; then
            echo "   ✓ Port $PORT is allowed in firewall"
        else
            echo "   ✗ Port $PORT is NOT allowed in firewall"
            echo "     Run: sudo ufw allow $PORT/tcp"
        fi
    else
        echo "   UFW firewall is inactive"
    fi
elif command -v firewall-cmd &> /dev/null; then
    if sudo firewall-cmd --state 2>/dev/null | grep -q "running"; then
        echo "   firewalld is active"
        if sudo firewall-cmd --list-ports 2>/dev/null | grep -q "$PORT"; then
            echo "   ✓ Port $PORT is allowed in firewall"
        else
            echo "   ✗ Port $PORT is NOT allowed in firewall"
            echo "     Run: sudo firewall-cmd --add-port=$PORT/tcp --permanent && sudo firewall-cmd --reload"
        fi
    else
        echo "   firewalld is not running"
    fi
else
    echo "   ⚠ Cannot check firewall (no ufw/firewalld found)"
fi
echo ""

# Summary
echo "================================================"
echo "SUMMARY - Which IP to Use"
echo "================================================"
echo ""
echo "✓ Use HOST IP (not container IP!)"
echo ""

# Detect primary IP
PRIMARY_IP=""
if command -v hostname &> /dev/null; then
    PRIMARY_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
if [ -z "$PRIMARY_IP" ]; then
    PRIMARY_IP="YOUR_SERVER_IP"
fi

echo "Access the admin panel at:"
echo ""
echo "From SAME machine:"
echo "  http://localhost:$PORT"
echo ""
echo "From OTHER machines on network:"
echo "  http://$PRIMARY_IP:$PORT"
echo ""
echo "─────────────────────────────────────"
echo "IMPORTANT:"
echo "  - Use HOST IP: $PRIMARY_IP"
echo "  - NOT container IP (like 172.17.x.x)"
echo "  - NOT 0.0.0.0 (it's a config value, not an IP)"
echo ""
echo "See WHICH-IP.md for detailed explanation"
echo ""
echo ""
echo "Common fixes if not working:"
echo "  1. Recreate container: docker-compose down && docker-compose up -d"
echo "  2. Check firewall: sudo ufw allow $PORT/tcp (or equivalent)"
echo "  3. Verify .env file has HTTP_PORT=$PORT"
echo "  4. Check no other service is using port $PORT"
echo ""
echo "For more help, see PORT-TROUBLESHOOTING.md"
echo ""
