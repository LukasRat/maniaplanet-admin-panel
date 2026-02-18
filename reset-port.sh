#!/bin/bash
# Complete reset script for persistent port mapping issues
# Usage: ./reset-port.sh [port]
# Example: ./reset-port.sh 3200

PORT=${1:-3200}

echo "================================================"
echo "ManiaPlanet Admin Panel - Port Reset Tool"
echo "================================================"
echo ""
echo "Target port: $PORT"
echo ""

# 1. Stop everything
echo "1. Stopping all containers..."
docker-compose down -v 2>/dev/null

# 2. Remove any orphaned containers
echo "2. Removing orphaned containers..."
ORPHANS=$(docker ps -a | grep maniaplanet | awk '{print $1}')
if [ -n "$ORPHANS" ]; then
    echo "   Found orphaned containers, removing..."
    echo "$ORPHANS" | xargs docker rm -f 2>/dev/null
else
    echo "   No orphaned containers found"
fi

# 3. Remove networks if they exist
echo "3. Cleaning up networks..."
docker network rm xmlrpc-network 2>/dev/null && echo "   Removed xmlrpc-network" || echo "   xmlrpc-network not found"
docker network rm database-network 2>/dev/null && echo "   Removed database-network" || echo "   database-network not found"

# 4. Verify/create .env
echo "4. Verifying .env file..."
if [ ! -f .env ]; then
    echo "   .env not found, creating from template..."
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        cat > .env << 'EOF'
HTTP_PORT=3200
HTTP_HOST=0.0.0.0
RPC_HOST=dedicated_stadium
RPC_PORT=5000
RPC_LOGIN=SuperAdmin
MANIAPLANET_MAPS_DIR=/maps
MAPS_PATH=./Maps/
EOF
    fi
fi

# Update port in .env
echo "   Updating HTTP_PORT to $PORT..."
if grep -q "HTTP_PORT=" .env; then
    sed -i.bak "s/HTTP_PORT=.*/HTTP_PORT=$PORT/" .env
else
    echo "HTTP_PORT=$PORT" >> .env
fi

# Ensure HTTP_HOST is set correctly
if ! grep -q "HTTP_HOST=0.0.0.0" .env; then
    echo "   Adding/fixing HTTP_HOST..."
    sed -i.bak "s/HTTP_HOST=.*/HTTP_HOST=0.0.0.0/" .env || echo "HTTP_HOST=0.0.0.0" >> .env
fi

echo "   Current .env settings:"
grep -E "HTTP_PORT|HTTP_HOST" .env | sed 's/^/     /'

# 5. Ensure Maps directory exists
echo "5. Ensuring Maps directory exists..."
mkdir -p ./Maps

# 6. Clean Docker cache
echo "6. Cleaning Docker cache..."
docker system prune -f > /dev/null 2>&1

# 7. Recreate with explicit env file
echo "7. Recreating containers with new configuration..."
docker-compose --env-file .env up -d --force-recreate

# 8. Wait for startup
echo "8. Waiting for container startup..."
sleep 5

# 9. Verify
echo "9. Verification:"
echo ""
echo "   Container status:"
if docker ps | grep -q maniaplanet-admin-panel; then
    docker ps | grep maniaplanet-admin-panel | sed 's/^/     /'
    echo "   ✓ Container is running"
else
    echo "   ✗ Container is not running!"
    echo ""
    echo "   Check logs:"
    echo "   docker logs maniaplanet-admin-panel"
    exit 1
fi

echo ""
echo "   Port mapping:"
PORT_MAPPING=$(docker ps --format "{{.Ports}}" | grep maniaplanet)
echo "     $PORT_MAPPING"

if echo "$PORT_MAPPING" | grep -q "$PORT"; then
    echo "   ✓ Port $PORT is correctly mapped"
else
    echo "   ✗ Port $PORT is NOT mapped correctly"
    echo "   Current mapping shows: $PORT_MAPPING"
fi

echo ""
echo "   Docker Compose config:"
docker-compose config | grep -A2 "ports:" | sed 's/^/     /'

echo ""
echo "================================================"
echo "Reset Complete!"
echo "================================================"
echo ""
echo "Access your admin panel at:"
echo "  - From this machine: http://localhost:$PORT/"

# Try to detect IP
if command -v hostname &> /dev/null; then
    PRIMARY_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -n "$PRIMARY_IP" ]; then
        echo "  - From network: http://$PRIMARY_IP:$PORT/"
    fi
fi

echo ""
echo "Test access:"
echo "  curl http://localhost:$PORT"
echo ""

# Test local access
if command -v curl &> /dev/null; then
    echo "Testing local access..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT 2>&1)
    if echo "$HTTP_CODE" | grep -q "200\|302"; then
        echo "✓ Success! Admin panel is accessible (HTTP $HTTP_CODE)"
    else
        echo "⚠️  Access test returned HTTP $HTTP_CODE"
        echo "   Check logs: docker logs maniaplanet-admin-panel"
    fi
fi

echo ""
echo "If issues persist, see: PERSISTENT-PORT-ISSUE.md"
echo ""
