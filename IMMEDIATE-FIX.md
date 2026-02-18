# IMMEDIATE FIX - Port Stuck at 3100

## Your Exact Problem

Your diagnostic shows:
- ✓ .env has HTTP_PORT=3200
- ✓ Container is running
- ✗ Port mapping shows 3100/tcp

**You've tried the standard fix and it didn't work.**

## Exact Steps to Fix Right Now

Copy and paste these commands **one by one** in your terminal:

### Step 1: Check Which Docker Compose File You're Using

```bash
# Check if container was started with standalone compose file
docker inspect maniaplanet-admin-panel | grep -i "com.docker.compose.project.config_files"

# This will show which compose file was used
```

**Result determines next steps:**
- If shows `docker-compose.standalone.yml` → use `-f docker-compose.standalone.yml` in all commands
- If shows `docker-compose.yml` → use normal commands

### Step 2: Complete Stop (Use Your Compose File)

**If you're using docker-compose.yml:**
```bash
docker-compose down -v
```

**If you're using docker-compose.standalone.yml:**
```bash
docker-compose -f docker-compose.standalone.yml down -v
```

### Step 3: Force Remove Container

```bash
docker rm -f maniaplanet-admin-panel
```

### Step 4: Verify .env File

```bash
# Show .env content
cat .env

# Should show:
# HTTP_PORT=3200
# HTTP_HOST=0.0.0.0
```

**If .env doesn't exist or is wrong:**
```bash
cat > .env << 'EOF'
HTTP_PORT=3200
HTTP_HOST=0.0.0.0
RPC_HOST=dedicated_stadium
RPC_PORT=5000
RPC_LOGIN=SuperAdmin
MANIAPLANET_MAPS_DIR=/maps
MAPS_PATH=./Maps/
EOF
```

### Step 5: Recreate with Force

**If you're using docker-compose.yml:**
```bash
docker-compose --env-file .env up -d --force-recreate --remove-orphans
```

**If you're using docker-compose.standalone.yml:**
```bash
docker-compose -f docker-compose.standalone.yml --env-file .env up -d --force-recreate --remove-orphans
```

### Step 6: Wait and Verify

```bash
# Wait 5 seconds
sleep 5

# Check port mapping
docker ps | grep maniaplanet

# You MUST see: 0.0.0.0:3200->3200/tcp
```

## If That Still Doesn't Work - Nuclear Option

If the above didn't work, do this complete reset:

```bash
# 1. Stop everything
docker-compose down -v 2>/dev/null
docker-compose -f docker-compose.standalone.yml down -v 2>/dev/null

# 2. Remove ALL maniaplanet containers
docker ps -a | grep maniaplanet | awk '{print $1}' | xargs docker rm -f 2>/dev/null

# 3. Remove networks
docker network rm xmlrpc-network 2>/dev/null
docker network rm database-network 2>/dev/null

# 4. Clean Docker cache
docker system prune -f

# 5. Verify .env
cat .env | grep HTTP_PORT

# 6. Recreate (use YOUR compose file)
docker-compose --env-file .env up -d --force-recreate

# 7. Verify
docker ps | grep maniaplanet
```

## Check What's Actually Running

```bash
# Show current container config
docker inspect maniaplanet-admin-panel | grep -A10 "ExposedPorts"

# Show what compose file was used
docker inspect maniaplanet-admin-panel | grep "com.docker.compose"
```

## Automated Fix

We have a script that should do this automatically:

```bash
./reset-port.sh 3200
```

**But if that doesn't work either**, it means there's a more fundamental issue. Try this:

## Alternative: Use Docker Directly (Bypass Docker Compose)

```bash
# Stop and remove existing container
docker stop maniaplanet-admin-panel
docker rm maniaplanet-admin-panel

# Build image
docker build -t maniaplanet-admin-panel .

# Run with explicit port
docker run -d \
  --name maniaplanet-admin-panel \
  -p 3200:3200 \
  -e HTTP_PORT=3200 \
  -e HTTP_HOST=0.0.0.0 \
  -e RPC_HOST=dedicated_stadium \
  -e RPC_PORT=5000 \
  -v $(pwd)/Maps:/maps \
  --network xmlrpc-network \
  maniaplanet-admin-panel

# Verify
docker ps | grep maniaplanet
```

## Most Common Issue: Using Wrong Docker Compose File

If you have both `docker-compose.yml` AND `docker-compose.standalone.yml`:

**Check which one you used to start:**
```bash
docker inspect maniaplanet-admin-panel | grep "config_files"
```

**Always use the SAME file for down and up:**
```bash
# If you started with standalone:
docker-compose -f docker-compose.standalone.yml down
docker-compose -f docker-compose.standalone.yml up -d

# If you started with normal:
docker-compose down
docker-compose up -d
```

## Verification Checklist

After trying the fix, verify ALL of these:

```bash
# 1. Check .env file
echo "=== .env file ==="
cat .env | grep HTTP

# 2. Check what docker-compose config will use
echo "=== Docker Compose Config ==="
docker-compose config | grep -A2 "ports:"

# 3. Check actual container port
echo "=== Container Port Mapping ==="
docker ps --format "{{.Names}}\t{{.Ports}}" | grep maniaplanet

# 4. Test access
echo "=== Testing Access ==="
curl -I http://localhost:3200
```

## Why This Keeps Happening

The issue is that `docker-compose down && docker-compose up -d` doesn't always work because:

1. **No `-v` flag** - volumes keep old config
2. **No `--force-recreate`** - compose might reuse existing container
3. **No `--env-file`** - compose might not read .env
4. **Orphaned containers** - old containers still exist
5. **Wrong compose file** - using standalone vs normal

## The Working Command

This is the command that should ALWAYS work:

```bash
docker-compose down -v && \
docker rm -f maniaplanet-admin-panel && \
docker-compose --env-file .env up -d --force-recreate --remove-orphans
```

Or use the reset script:
```bash
./reset-port.sh 3200
```

## Still Stuck?

If NONE of the above works, collect this information:

```bash
{
    echo "=== Docker Compose Files ==="
    ls -la docker-compose*.yml
    
    echo ""
    echo "=== .env Content ==="
    cat .env
    
    echo ""
    echo "=== All Maniaplanet Containers ==="
    docker ps -a | grep maniaplanet
    
    echo ""
    echo "=== Container Inspect ==="
    docker inspect maniaplanet-admin-panel
    
    echo ""
    echo "=== Docker Compose Config ==="
    docker-compose config
    
} > fix-debug.txt

cat fix-debug.txt
```

Then share fix-debug.txt.

## TL;DR - Just Run This

```bash
# The nuclear option that should ALWAYS work:
docker stop maniaplanet-admin-panel
docker rm -f maniaplanet-admin-panel
docker-compose down -v
docker system prune -f
cat > .env << 'EOF'
HTTP_PORT=3200
HTTP_HOST=0.0.0.0
RPC_HOST=dedicated_stadium
RPC_PORT=5000
RPC_LOGIN=SuperAdmin
MANIAPLANET_MAPS_DIR=/maps
MAPS_PATH=./Maps/
EOF
docker-compose --env-file .env up -d --force-recreate --remove-orphans
sleep 5
docker ps | grep maniaplanet
curl http://localhost:3200
```

If this doesn't show port 3200, there's something fundamentally wrong with your Docker setup.
