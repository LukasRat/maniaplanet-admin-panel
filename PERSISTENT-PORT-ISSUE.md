# Persistent Port Mapping Issue - Advanced Troubleshooting

## Your Problem

You've changed `HTTP_PORT=3200` in your `.env` file and ran `docker-compose down && docker-compose up -d`, but the port mapping **still shows 3100/tcp** instead of 3200.

The diagnostic shows:
```
✓ HTTP_PORT is set to 3200 in .env
✗ ERROR: Port 3200 is NOT mapped correctly!
  Current mapping: 3100/tcp
```

**Standard fix didn't work!**

## Why This Happens

Docker Compose might not be reading your `.env` file correctly due to:
1. **Cached containers** still using old settings
2. **Orphaned networks or volumes** preserving old configuration
3. **.env file** not in the correct location or has encoding issues
4. **Multiple containers** with the same name
5. **Docker Compose cache** not being cleared

## Advanced Solutions

### Solution 1: Complete Cleanup (Most Effective)

```bash
# 1. Stop everything
docker-compose down -v

# 2. Remove the specific container
docker rm -f maniaplanet-admin-panel 2>/dev/null || true

# 3. Remove associated networks (if they exist)
docker network rm xmlrpc-network 2>/dev/null || true
docker network rm database-network 2>/dev/null || true

# 4. Verify .env file
cat .env | grep HTTP_PORT

# 5. Recreate everything
docker-compose up -d

# 6. Verify immediately
docker ps | grep maniaplanet
```

### Solution 2: Force Recreate with Explicit Env File

```bash
# Stop containers
docker-compose down

# Explicitly specify env file and force recreate
docker-compose --env-file .env up -d --force-recreate

# Verify
docker ps --format "{{.Names}}\t{{.Ports}}" | grep maniaplanet
```

### Solution 3: Nuclear Option - Complete Docker Reset

**Warning:** This removes ALL Docker containers, networks, and unused images

```bash
# Stop your containers first
docker-compose down -v

# Complete Docker cleanup
docker system prune -af --volumes

# Recreate
docker-compose up -d

# Verify
docker ps | grep maniaplanet
```

### Solution 4: Check for Orphaned Containers

```bash
# List all containers (including stopped)
docker ps -a | grep maniaplanet

# You might see multiple containers:
# maniaplanet-admin-panel  (old one)
# maniaplanet-admin-panel_1
# project_maniaplanet-admin-panel_1

# Remove ALL of them
docker ps -a | grep maniaplanet | awk '{print $1}' | xargs docker rm -f

# Now recreate
docker-compose up -d
```

### Solution 5: Verify .env File Location and Content

```bash
# 1. Check file location (must be in same dir as docker-compose.yml)
ls -la .env docker-compose.yml

# 2. Check file permissions
ls -l .env

# 3. Check for hidden characters (BOM, etc.)
file .env

# 4. Recreate .env cleanly
cat > .env << 'EOF'
HTTP_PORT=3200
HTTP_HOST=0.0.0.0
RPC_HOST=dedicated_stadium
RPC_PORT=5000
RPC_LOGIN=SuperAdmin
MANIAPLANET_MAPS_DIR=/maps
MAPS_PATH=./Maps/
EOF

# 5. Verify content
cat .env

# 6. Recreate container
docker-compose down
docker-compose up -d
```

## Step-by-Step Diagnostic

### Step 1: Verify .env File

```bash
# Check location
pwd
ls -la .env docker-compose.yml

# Check content
cat .env | grep HTTP_PORT

# Should show:
# HTTP_PORT=3200
```

**If .env is missing or in wrong location:**
- It must be in the SAME directory as docker-compose.yml
- Create it: `cp .env.example .env`

### Step 2: Check for Multiple Containers

```bash
# List all maniaplanet containers
docker ps -a | grep maniaplanet

# Count them
docker ps -a | grep maniaplanet | wc -l
```

**If you see more than one:**
```bash
# Remove all of them
docker ps -a | grep maniaplanet | awk '{print $1}' | xargs docker rm -f
```

### Step 3: Check Docker Compose Version

```bash
# Check version
docker-compose --version

# Older versions might not read .env correctly
# If version < 1.25, upgrade Docker Compose
```

### Step 4: Test with Explicit Environment Variable

```bash
# Try passing the port directly
HTTP_PORT=3200 docker-compose up -d

# Or use --env-file explicitly
docker-compose --env-file .env up -d
```

### Step 5: Check What Docker Compose Sees

```bash
# Show resolved configuration
docker-compose config

# Look for:
# ports:
#   - "3200:3200"
#
# If it shows 3100, .env isn't being read
```

**If config shows 3100:**
- .env file is not being read
- Try explicit: `docker-compose --env-file .env config`

## Common Issues and Fixes

### Issue 1: .env File Has Wrong Encoding

**Symptom:** File looks correct but not being read

**Check:**
```bash
file .env
# Should show: ASCII text or UTF-8 Unicode text
# NOT: UTF-8 Unicode (with BOM) text
```

**Fix:**
```bash
# Remove BOM and recreate
tr -d '\357\273\277' < .env > .env.tmp
mv .env.tmp .env
```

### Issue 2: .env File Has Windows Line Endings

**Symptom:** Created .env on Windows, using on Linux

**Check:**
```bash
file .env
# If shows CRLF line terminators, it's Windows format
```

**Fix:**
```bash
# Convert to Unix format
dos2unix .env
# or
sed -i 's/\r$//' .env
```

### Issue 3: Docker Compose Using Different Env File

**Symptom:** Another .env file exists somewhere

**Check:**
```bash
# Find all .env files
find . -name ".env" -type f
```

**Fix:**
```bash
# Remove unwanted .env files
# Keep only the one in docker-compose.yml directory
```

### Issue 4: Container Name Conflict

**Symptom:** Container exists with same name

**Check:**
```bash
docker ps -a --filter "name=maniaplanet"
```

**Fix:**
```bash
# Remove all containers with that name
docker rm -f $(docker ps -a --filter "name=maniaplanet" -q)
```

### Issue 5: Volumes Caching Old Config

**Symptom:** Even after recreate, uses old port

**Fix:**
```bash
# Remove with volumes
docker-compose down -v

# Or manually remove volumes
docker volume ls | grep maniaplanet
docker volume rm <volume_name>
```

## Complete Reset Procedure

If nothing else works, use this complete reset:

```bash
#!/bin/bash

echo "=== Complete Reset Procedure ==="
echo ""

# 1. Stop everything
echo "1. Stopping containers..."
docker-compose down -v

# 2. Remove any orphaned containers
echo "2. Removing orphaned containers..."
docker ps -a | grep maniaplanet | awk '{print $1}' | xargs docker rm -f 2>/dev/null || true

# 3. Remove networks
echo "3. Removing networks..."
docker network rm xmlrpc-network 2>/dev/null || true
docker network rm database-network 2>/dev/null || true

# 4. Verify .env
echo "4. Verifying .env file..."
if [ ! -f .env ]; then
    echo "   Creating .env from template..."
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

echo "   Current .env content:"
cat .env | grep HTTP

# 5. Clean Docker cache (optional but recommended)
echo "5. Cleaning Docker cache..."
docker system prune -f

# 6. Recreate with explicit env file
echo "6. Recreating containers..."
docker-compose --env-file .env up -d --force-recreate

# 7. Wait for startup
echo "7. Waiting for startup..."
sleep 5

# 8. Verify
echo "8. Verification:"
echo ""
echo "Container status:"
docker ps | grep maniaplanet

echo ""
echo "Port mapping:"
docker ps --format "{{.Ports}}" | grep maniaplanet

echo ""
echo "Config check:"
docker-compose config | grep -A2 "ports:"

echo ""
echo "=== Reset Complete ==="
echo ""
echo "Access at: http://localhost:3200/"
```

Save this as `reset-port.sh` and run:
```bash
chmod +x reset-port.sh
./reset-port.sh
```

## Verification Commands

After trying any fix, verify it worked:

```bash
# 1. Check container is running with correct port
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep maniaplanet

# Expected: 0.0.0.0:3200->3200/tcp

# 2. Check what docker-compose config shows
docker-compose config | grep -A2 "ports:"

# Expected:
#   ports:
#   - "3200:3200"

# 3. Check .env is being read
docker-compose config | grep HTTP_PORT

# Expected: HTTP_PORT: "3200"

# 4. Test actual access
curl http://localhost:3200

# Should return HTML
```

## Prevention

To avoid this issue in the future:

### 1. Always Use Complete Commands
```bash
# Good:
docker-compose down -v
docker-compose up -d

# Better:
docker-compose down -v
docker-compose --env-file .env up -d --force-recreate
```

### 2. Create Helper Script

Create `change-port.sh`:
```bash
#!/bin/bash
NEW_PORT=${1:-3200}

echo "Changing port to $NEW_PORT..."

# Update .env
sed -i "s/HTTP_PORT=.*/HTTP_PORT=$NEW_PORT/" .env

# Complete reset
docker-compose down -v
docker rm -f maniaplanet-admin-panel 2>/dev/null || true

# Recreate
docker-compose up -d --force-recreate

# Verify
echo ""
echo "New configuration:"
docker ps | grep maniaplanet
```

Usage:
```bash
chmod +x change-port.sh
./change-port.sh 3200
```

### 3. Always Verify After Changes

```bash
# After any .env change, always verify:
docker-compose config | grep HTTP_PORT
docker ps | grep maniaplanet
```

## Still Not Working?

### Collect Debug Information

```bash
# Save all information
{
    echo "=== Docker Compose Version ==="
    docker-compose --version
    
    echo ""
    echo "=== .env File Location ==="
    ls -la .env docker-compose.yml
    
    echo ""
    echo "=== .env Content ==="
    cat .env
    
    echo ""
    echo "=== .env File Type ==="
    file .env
    
    echo ""
    echo "=== All Maniaplanet Containers ==="
    docker ps -a | grep maniaplanet
    
    echo ""
    echo "=== Docker Compose Config ==="
    docker-compose config
    
    echo ""
    echo "=== Current Port Mapping ==="
    docker ps --format "{{.Names}}\t{{.Ports}}" | grep maniaplanet
    
    echo ""
    echo "=== Docker Networks ==="
    docker network ls | grep -E "xmlrpc|database|maniaplanet"
    
} > persistent-port-debug.txt

cat persistent-port-debug.txt
```

### Try Alternative Approach

If Docker Compose continues to have issues, use pure Docker:

```bash
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
  -v ./Maps:/maps \
  maniaplanet-admin-panel

# Verify
docker ps | grep maniaplanet
```

## Summary

For persistent port mapping issues:

1. **Quick try:**
   ```bash
   docker-compose down -v
   docker-compose --env-file .env up -d --force-recreate
   ```

2. **If that fails:**
   ```bash
   docker rm -f maniaplanet-admin-panel
   docker-compose up -d
   ```

3. **If still failing:**
   - Run the complete reset procedure above
   - Check .env file encoding and location
   - Verify no orphaned containers

4. **Nuclear option:**
   ```bash
   docker system prune -af --volumes
   docker-compose up -d
   ```

The key is using `-v` flag with `down`, `--force-recreate` with `up`, and ensuring .env is in the correct location with correct encoding.
