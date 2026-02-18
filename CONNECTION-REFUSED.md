# Connection Refused - Troubleshooting Guide

## Your Error

You're seeing a "Connection Refused" error when trying to access the admin panel. The diagnostic shows:
- ⚠️ Could not detect port from container
- ⚠️ Local access test failed

This means the container is running, but the application inside is not responding.

## Quick Diagnosis

Run these commands to check what's happening:

```bash
# 1. Check container status
docker ps -a | grep maniaplanet-admin-panel

# 2. Check container logs (last 50 lines)
docker logs --tail 50 maniaplanet-admin-panel

# 3. Check if container is restarting
docker ps -a --filter "name=maniaplanet-admin-panel" --format "{{.Status}}"
```

## Common Causes and Fixes

### Cause 1: Container Is Restarting (Most Common)

**Symptom:** Container shows "Restarting" or keeps disappearing from `docker ps`

**Check:**
```bash
docker ps -a | grep maniaplanet
```

**Look for:**
- Status: "Restarting (1) X seconds ago"
- Status: "Exited (1) X seconds ago"

**Why this happens:**
- Application crashes immediately after starting
- Missing dependencies
- Configuration error
- Port already in use by another process

**Check logs:**
```bash
docker logs --tail 100 maniaplanet-admin-panel
```

**Common log errors:**
```
Error: Cannot find module 'express'
→ Fix: npm install wasn't run during build

Error: listen EADDRINUSE: address already in use
→ Fix: Port is already taken

Error: ENOENT: no such file or directory
→ Fix: Missing maps directory or wrong path
```

**Fix:**
```bash
# Rebuild container completely
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Check logs immediately
docker logs -f maniaplanet-admin-panel
```

### Cause 2: Application Failed to Start

**Symptom:** Container runs but application shows error in logs

**Check logs for these errors:**

**Error: Cannot find module 'express'**
```bash
# The Docker image wasn't built correctly
# Rebuild with no cache:
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

**Error: EADDRINUSE (Port already in use)**
```bash
# Another process is using the port
# Find what's using it:
sudo lsof -i :3200
# or
sudo netstat -tulpn | grep 3200

# Kill the process or change your port in .env
```

**Error: ENOENT (File/Directory not found)**
```bash
# Maps directory doesn't exist
# Check your docker-compose.yml volumes section
# Make sure MAPS_PATH points to an existing directory:
mkdir -p ./Maps
docker-compose down
docker-compose up -d
```

### Cause 3: Wrong HTTP_HOST Configuration

**Symptom:** Container runs, logs show "Started on 127.0.0.1"

**Check:**
```bash
docker logs maniaplanet-admin-panel | grep "Network:"
```

**If you see:**
```
🌐 Network:  http://127.0.0.1:3200
```

**Problem:** Application is only listening on localhost (container internal)

**Fix:**
```bash
# Edit .env file
echo "HTTP_HOST=0.0.0.0" >> .env

# Recreate container
docker-compose down
docker-compose up -d

# Verify
docker logs maniaplanet-admin-panel | grep "Network:"
# Should show: http://0.0.0.0:3200
```

### Cause 4: Container Runs But Application Didn't Start

**Symptom:** Container shows "Up" but no application logs

**Check:**
```bash
# See full logs
docker logs maniaplanet-admin-panel

# Check what's running inside container
docker exec maniaplanet-admin-panel ps aux

# Check if node process is running
docker exec maniaplanet-admin-panel ps aux | grep node
```

**If no node process:**
```bash
# Something prevented startup
# Check the full logs:
docker logs maniaplanet-admin-panel

# Try starting manually to see error:
docker exec -it maniaplanet-admin-panel npm start
```

### Cause 5: Port Mapping Issue

**Symptom:** Container runs, app starts, but can't connect

**Check port mapping:**
```bash
docker ps | grep maniaplanet
```

**Expected:**
```
0.0.0.0:3200->3200/tcp
```

**If you see:**
```
3200/tcp  (no 0.0.0.0)
```

**Problem:** Port not mapped to host

**Fix docker-compose.yml:**
```yaml
ports:
  - "${HTTP_PORT:-3100}:${HTTP_PORT:-3100}"
```

**Recreate:**
```bash
docker-compose down
docker-compose up -d
```

### Cause 6: Firewall or SELinux

**Symptom:** Everything looks correct but still can't connect

**Check SELinux (if on RHEL/CentOS/Fedora):**
```bash
getenforce
# If "Enforcing":
sudo setenforce 0  # Temporary
# Or add proper rules
```

**Check iptables:**
```bash
sudo iptables -L -n | grep 3200
```

**Check firewall:**
```bash
# UFW
sudo ufw status

# firewalld
sudo firewall-cmd --list-ports
```

## Step-by-Step Diagnosis

### Step 1: Is Container Running?

```bash
docker ps -a | grep maniaplanet-admin-panel
```

**Output shows "Up X seconds":**
- ✓ Container is running
- → Go to Step 2

**Output shows "Exited" or "Restarting":**
- ✗ Container is not running properly
- → Check logs: `docker logs maniaplanet-admin-panel`
- → Rebuild: `docker-compose down && docker-compose build --no-cache && docker-compose up -d`

### Step 2: Check Container Logs

```bash
docker logs --tail 50 maniaplanet-admin-panel
```

**Look for:**
- ✓ "Maniaplanet Admin Panel Server Started!"
- ✗ "Error:", "Cannot find module", "EADDRINUSE", "ENOENT"

**If you see errors:**
- Check the specific error fix above
- Most common: "Cannot find module" → rebuild
- Second most: "EADDRINUSE" → port conflict

### Step 3: Check What Application Listens On

```bash
docker logs maniaplanet-admin-panel | grep "Network:"
```

**Expected:**
```
🌐 Network:  http://0.0.0.0:3200
```

**If you see `127.0.0.1`:**
- Add `HTTP_HOST=0.0.0.0` to .env
- Recreate container

### Step 4: Test Inside Container

```bash
# Test if app responds inside container
docker exec maniaplanet-admin-panel curl -s http://localhost:3200 | head -5
```

**If this works:**
- Problem is port mapping or firewall
- Check: `docker ps` for port mapping

**If this fails:**
- Application not running inside container
- Check: `docker exec maniaplanet-admin-panel ps aux | grep node`

### Step 5: Check Port Mapping

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep maniaplanet
```

**Expected:**
```
maniaplanet-admin-panel    0.0.0.0:3200->3200/tcp
```

**If missing 0.0.0.0:**
- Port not exposed correctly
- Fix docker-compose.yml and recreate

## Complete Fix Workflow

Try these steps in order:

```bash
# 1. Check current state
docker ps -a | grep maniaplanet-admin-panel
docker logs --tail 50 maniaplanet-admin-panel

# 2. If seeing errors, rebuild completely
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# 3. Wait for startup
sleep 10

# 4. Check logs again
docker logs --tail 30 maniaplanet-admin-panel

# 5. Verify it's accessible
curl http://localhost:3200

# 6. If still failing, check inside container
docker exec maniaplanet-admin-panel ps aux
docker exec maniaplanet-admin-panel curl http://localhost:3200
```

## Quick Fixes

### Fix 1: Complete Rebuild
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
sleep 10
docker logs maniaplanet-admin-panel
```

### Fix 2: Ensure Correct Configuration
```bash
# Create proper .env file
cat > .env << 'EOF'
HTTP_PORT=3200
HTTP_HOST=0.0.0.0
RPC_HOST=dedicated_stadium
RPC_PORT=5000
RPC_LOGIN=SuperAdmin
MANIAPLANET_MAPS_DIR=/maps
MAPS_PATH=./Maps/
EOF

# Ensure Maps directory exists
mkdir -p ./Maps

# Recreate
docker-compose down
docker-compose up -d
```

### Fix 3: Check and Kill Port Conflicts
```bash
# Find what's using the port
sudo lsof -i :3200
# or
sudo netstat -tulpn | grep 3200

# Kill the process (replace PID)
sudo kill -9 <PID>

# Restart container
docker-compose restart
```

### Fix 4: Reset Everything
```bash
# Nuclear option - reset everything
docker-compose down -v
docker system prune -f
docker-compose build --no-cache
docker-compose up -d
```

## Diagnostic Commands Summary

```bash
# Container status
docker ps -a | grep maniaplanet

# Container logs (last 50 lines)
docker logs --tail 50 maniaplanet-admin-panel

# Follow logs in real-time
docker logs -f maniaplanet-admin-panel

# Check what's running inside
docker exec maniaplanet-admin-panel ps aux

# Test inside container
docker exec maniaplanet-admin-panel curl http://localhost:3200

# Check port mapping
docker ps --format "{{.Ports}}" | grep maniaplanet

# Check if port is in use on host
sudo lsof -i :3200
sudo netstat -tulpn | grep 3200

# Container detailed info
docker inspect maniaplanet-admin-panel

# Container resource usage
docker stats maniaplanet-admin-panel --no-stream
```

## Still Not Working?

### Collect Debug Information

```bash
# Save all diagnostic info to a file
{
    echo "=== Container Status ==="
    docker ps -a | grep maniaplanet
    echo ""
    
    echo "=== Container Logs ==="
    docker logs --tail 100 maniaplanet-admin-panel
    echo ""
    
    echo "=== Port Mapping ==="
    docker ps --format "{{.Ports}}" | grep maniaplanet
    echo ""
    
    echo "=== Running Processes Inside Container ==="
    docker exec maniaplanet-admin-panel ps aux 2>/dev/null || echo "Container not running"
    echo ""
    
    echo "=== Docker Compose Config ==="
    docker-compose config
    echo ""
    
    echo "=== .env File ==="
    cat .env
    echo ""
    
    echo "=== Port Usage on Host ==="
    sudo lsof -i :3200 2>/dev/null || echo "Port not in use or no permission"
    echo ""
} > debug-info.txt

echo "Debug info saved to debug-info.txt"
cat debug-info.txt
```

### Get Help

Share the debug-info.txt file with:
- Container logs showing errors
- Port mapping information
- .env configuration

## Prevention

To avoid "Connection Refused" in the future:

1. **Always check logs after starting:**
   ```bash
   docker-compose up -d
   sleep 5
   docker logs maniaplanet-admin-panel
   ```

2. **Use the diagnostic script:**
   ```bash
   ./diagnose-port.sh 3200
   ```

3. **Ensure .env has HTTP_HOST=0.0.0.0:**
   ```bash
   grep HTTP_HOST .env
   ```

4. **Create Maps directory before starting:**
   ```bash
   mkdir -p ./Maps
   ```

5. **Check no port conflicts:**
   ```bash
   sudo lsof -i :3200
   ```

## Related Guides

- **PORT-TROUBLESHOOTING.md** - Port configuration issues
- **EXTERNAL-ACCESS.md** - External access problems
- **WHICH-IP.md** - IP address confusion
- **diagnose-port.sh** - Automated diagnostic tool
