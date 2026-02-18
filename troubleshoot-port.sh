#!/bin/bash
# Troubleshooting script to diagnose port mapping issues
# Usage: ./troubleshoot-port.sh

echo "================================================"
echo "ManiaPlanet Admin Panel - Port Troubleshooter"
echo "================================================"
echo ""

echo "1. Checking Docker Compose files..."
echo "   Available compose files:"
ls -la docker-compose*.yml 2>/dev/null | sed 's/^/     /'
echo ""

echo "2. Checking .env file..."
if [ -f .env ]; then
    echo "   ✓ .env file exists"
    echo "   Content:"
    cat .env | grep -E "HTTP_PORT|HTTP_HOST" | sed 's/^/     /'
else
    echo "   ✗ .env file NOT found!"
    echo "   Create it with: cp .env.example .env"
fi
echo ""

echo "3. Checking which compose file was used..."
if docker inspect maniaplanet-admin-panel >/dev/null 2>&1; then
    COMPOSE_CONFIG=$(docker inspect maniaplanet-admin-panel | grep -i "com.docker.compose.project.config_files" | head -1)
    if [ -n "$COMPOSE_CONFIG" ]; then
        echo "   Container config: $COMPOSE_CONFIG"
    else
        echo "   Could not determine compose file used"
    fi
else
    echo "   Container not found or not running"
fi
echo ""

echo "4. Checking all maniaplanet containers..."
CONTAINERS=$(docker ps -a | grep maniaplanet)
if [ -n "$CONTAINERS" ]; then
    echo "$CONTAINERS" | sed 's/^/   /'
    echo ""
    COUNT=$(echo "$CONTAINERS" | wc -l)
    if [ "$COUNT" -gt 1 ]; then
        echo "   ⚠️  WARNING: Multiple containers found!"
        echo "   This might cause issues. Remove extras with:"
        echo "   docker ps -a | grep maniaplanet | awk '{print \$1}' | xargs docker rm -f"
    fi
else
    echo "   No maniaplanet containers found"
fi
echo ""

echo "5. Checking what docker-compose config will use..."
if [ -f .env ]; then
    echo "   docker-compose.yml config:"
    docker-compose config 2>/dev/null | grep -A3 "ports:" | sed 's/^/     /'
    echo ""
    
    if [ -f docker-compose.standalone.yml ]; then
        echo "   docker-compose.standalone.yml config:"
        docker-compose -f docker-compose.standalone.yml config 2>/dev/null | grep -A3 "ports:" | sed 's/^/     /'
    fi
else
    echo "   Cannot check (no .env file)"
fi
echo ""

echo "6. Checking current port mapping..."
if docker ps | grep -q maniaplanet-admin-panel; then
    PORT_MAP=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep maniaplanet)
    echo "   $PORT_MAP"
    
    # Extract port number
    CURRENT_PORT=$(echo "$PORT_MAP" | grep -oP '0.0.0.0:\K[0-9]+' | head -1)
    if [ -n "$CURRENT_PORT" ]; then
        echo "   Current port: $CURRENT_PORT"
        
        if [ -f .env ]; then
            EXPECTED_PORT=$(grep "HTTP_PORT=" .env | cut -d'=' -f2)
            if [ "$CURRENT_PORT" = "$EXPECTED_PORT" ]; then
                echo "   ✓ Port matches .env!"
            else
                echo "   ✗ Port MISMATCH! Expected: $EXPECTED_PORT, Got: $CURRENT_PORT"
            fi
        fi
    fi
else
    echo "   Container not running"
fi
echo ""

echo "7. Testing local access..."
if docker ps | grep -q maniaplanet-admin-panel; then
    PORT_MAP=$(docker ps --format "{{.Ports}}" | grep maniaplanet)
    TEST_PORT=$(echo "$PORT_MAP" | grep -oP '0.0.0.0:\K[0-9]+' | head -1)
    
    if [ -n "$TEST_PORT" ]; then
        echo "   Testing http://localhost:$TEST_PORT ..."
        if command -v curl >/dev/null 2>&1; then
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$TEST_PORT 2>&1)
            if echo "$HTTP_CODE" | grep -q "200\|302"; then
                echo "   ✓ Success! (HTTP $HTTP_CODE)"
            else
                echo "   ✗ Failed (HTTP $HTTP_CODE)"
            fi
        else
            echo "   curl not available, skipping test"
        fi
    fi
fi
echo ""

echo "================================================"
echo "DIAGNOSIS SUMMARY"
echo "================================================"
echo ""

# Final recommendation
if [ ! -f .env ]; then
    echo "❌ CRITICAL: No .env file found!"
    echo "   Create it: cp .env.example .env"
    echo ""
fi

CONTAINERS_COUNT=$(docker ps -a | grep maniaplanet | wc -l)
if [ "$CONTAINERS_COUNT" -gt 1 ]; then
    echo "⚠️  Multiple containers exist!"
    echo "   Fix: docker ps -a | grep maniaplanet | awk '{print \$1}' | xargs docker rm -f"
    echo ""
fi

if docker ps | grep -q maniaplanet-admin-panel; then
    PORT_MAP=$(docker ps --format "{{.Ports}}" | grep maniaplanet)
    CURRENT_PORT=$(echo "$PORT_MAP" | grep -oP '0.0.0.0:\K[0-9]+' | head -1)
    
    if [ -f .env ]; then
        EXPECTED_PORT=$(grep "HTTP_PORT=" .env | cut -d'=' -f2)
        if [ "$CURRENT_PORT" != "$EXPECTED_PORT" ]; then
            echo "❌ PORT MISMATCH DETECTED!"
            echo "   Expected: $EXPECTED_PORT"
            echo "   Current: $CURRENT_PORT"
            echo ""
            echo "   SOLUTION:"
            echo "   ./reset-port.sh $EXPECTED_PORT"
            echo ""
            echo "   Or manually:"
            echo "   docker-compose down -v"
            echo "   docker rm -f maniaplanet-admin-panel"
            echo "   docker-compose --env-file .env up -d --force-recreate --remove-orphans"
            echo ""
        else
            echo "✓ All checks passed! Port is correctly set to $CURRENT_PORT"
        fi
    fi
else
    echo "ℹ️  Container not running"
    echo "   Start it: docker-compose up -d"
fi

echo ""
echo "For detailed fix instructions, see: IMMEDIATE-FIX.md"
echo ""
