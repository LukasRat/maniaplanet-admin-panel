# QUICK FIX: Application Not Accessible from Outside Container

If you're trying to access the admin panel from **outside the container** (e.g., from another computer or your web browser), follow these steps.

## The Problem

You've set `HTTP_PORT=3200` in `.env`, ran `docker-compose down` and `docker-compose up -d`, but still cannot access the application from outside the container on `http://YOUR_IP:3200/`

## Quick Diagnostic

Run the diagnostic script first:
```bash
./diagnose-port.sh 3200
```

This will check all common issues automatically.

## Step-by-Step Fix

### Step 1: Verify Container Configuration

```bash
# Check if container is running
docker ps

# You should see something like:
# CONTAINER ID   IMAGE                    PORTS                    NAMES
# abc123...      maniaplanet-admin-panel  0.0.0.0:3200->3200/tcp   maniaplanet-admin-panel
```

**Critical Check:** The port mapping MUST show `0.0.0.0:3200->3200/tcp`
- `0.0.0.0` means "listen on all network interfaces" (allows external access)
- If you see `127.0.0.1:3200->3200/tcp`, it only allows local access

### Step 2: Verify .env Configuration

```bash
cat .env | grep HTTP
```

**Must have:**
```env
HTTP_PORT=3200
HTTP_HOST=0.0.0.0
```

**If HTTP_HOST is not set to 0.0.0.0:**
1. Edit .env: `nano .env` or `vi .env`
2. Set `HTTP_HOST=0.0.0.0`
3. Recreate container: `docker-compose down && docker-compose up -d`

### Step 3: Check Container Logs

```bash
docker logs maniaplanet-admin-panel | grep "Network:"
```

**Should show:**
```
🌐 Network:  http://0.0.0.0:3200
```

**If it shows `http://127.0.0.1:3200`:**
- The application is only listening on localhost (internal only)
- Fix: Set `HTTP_HOST=0.0.0.0` in .env and recreate container

### Step 4: Test Local Access First

```bash
curl http://localhost:3200
```

If this doesn't work, the container itself has an issue. Check:
```bash
docker logs maniaplanet-admin-panel
```

### Step 5: Find Your Server's IP Address

```bash
# On Linux/Mac:
ip addr show | grep "inet " | grep -v "127.0.0.1"

# Or:
ifconfig | grep "inet " | grep -v "127.0.0.1"

# On Windows (in PowerShell):
ipconfig
```

Example output:
```
inet 192.168.178.43/24
```

Your server IP is `192.168.178.43`

### Step 6: Test External Access

From another computer on the same network:
```
http://192.168.178.43:3200/
```

Or use curl:
```bash
curl http://192.168.178.43:3200
```

### Step 7: Check Firewall

If local access works but external doesn't, it's likely a firewall issue.

**Linux (UFW):**
```bash
# Check firewall status
sudo ufw status

# Allow port 3200
sudo ufw allow 3200/tcp

# Verify
sudo ufw status | grep 3200
```

**Linux (firewalld):**
```bash
# Check firewall status
sudo firewall-cmd --state

# Allow port 3200
sudo firewall-cmd --add-port=3200/tcp --permanent
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-ports
```

**Windows:**
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules"
4. Click "New Rule"
5. Select "Port" → Next
6. Select "TCP" → Specific local ports: 3200 → Next
7. Select "Allow the connection" → Next
8. Select all profiles → Next
9. Name it "ManiaPlanet Admin Panel" → Finish

### Step 8: Check for Conflicting Services

Another service might be using port 3200:

```bash
# Check what's using the port
netstat -tulpn | grep 3200
# or
ss -tulpn | grep 3200

# Or check with lsof
lsof -i :3200
```

If another service is using it, either:
1. Stop that service
2. Change `HTTP_PORT` to a different port (e.g., 3300)

## Common Issues and Solutions

### Issue 1: Port mapping shows 127.0.0.1 instead of 0.0.0.0

**Symptom:** `docker ps` shows `127.0.0.1:3200->3200/tcp`

**Cause:** Docker is configured to only bind to localhost

**Fix:**
```bash
# Check docker-compose.yml ports section
cat docker-compose.yml | grep -A2 "ports:"

# Should be:
#   ports:
#     - "${HTTP_PORT:-3100}:${HTTP_PORT:-3100}"
# 
# NOT:
#   ports:
#     - "127.0.0.1:${HTTP_PORT:-3100}:${HTTP_PORT:-3100}"

# If incorrect, fix docker-compose.yml and recreate:
docker-compose down
docker-compose up -d
```

### Issue 2: Application logs show wrong port

**Symptom:** Container logs show `:3100` instead of `:3200`

**Cause:** Environment variables not loaded

**Fix:**
```bash
# Ensure .env is in same directory as docker-compose.yml
ls -la .env docker-compose.yml

# Completely remove and recreate container
docker-compose down
docker-compose up -d

# Verify
docker logs maniaplanet-admin-panel | tail -20
```

### Issue 3: Multiple containers running

**Symptom:** Old and new containers both running

**Fix:**
```bash
# List all containers (including stopped)
docker ps -a | grep maniaplanet

# Remove all old containers
docker rm -f $(docker ps -a | grep maniaplanet-admin-panel | awk '{print $1}')

# Recreate properly
docker-compose down
docker-compose up -d
```

### Issue 4: Network mode is "host"

**Symptom:** Port mapping doesn't appear in `docker ps`

**Cause:** Container is using host network mode

**Check:**
```bash
docker inspect maniaplanet-admin-panel --format '{{.HostConfig.NetworkMode}}'
```

**Fix:** Ensure docker-compose.yml doesn't have `network_mode: host`

### Issue 5: Firewall blocking despite rules

**Symptom:** Firewall rules exist but still blocked

**Fix:**
```bash
# Restart firewall service
sudo systemctl restart ufw
# or
sudo systemctl restart firewalld

# Check if Docker chains are correct
sudo iptables -L -n | grep 3200
```

## Testing Checklist

Go through this checklist systematically:

- [ ] `.env` file exists in same directory as `docker-compose.yml`
- [ ] `.env` contains `HTTP_PORT=3200` and `HTTP_HOST=0.0.0.0`
- [ ] Ran `docker-compose down` (not just stop)
- [ ] Ran `docker-compose up -d`
- [ ] `docker ps` shows `0.0.0.0:3200->3200/tcp` (not 127.0.0.1)
- [ ] `docker logs` shows `🌐 Network: http://0.0.0.0:3200`
- [ ] `curl http://localhost:3200` returns HTML
- [ ] Know server's IP address (e.g., 192.168.178.43)
- [ ] Firewall allows port 3200 (`sudo ufw allow 3200/tcp`)
- [ ] No other service is using port 3200 (`netstat -tulpn | grep 3200`)
- [ ] Can access from browser: `http://YOUR_IP:3200/`

## Still Not Working?

### Run Full Diagnostics

```bash
# Run the diagnostic script
./diagnose-port.sh 3200

# Check Docker daemon logs
sudo journalctl -u docker | tail -50

# Check system logs
dmesg | tail -50
```

### Collect Information for Support

```bash
# Save diagnostic output
./diagnose-port.sh 3200 > diagnostic-output.txt

# Add docker-compose config
docker-compose config >> diagnostic-output.txt

# Add container inspect
docker inspect maniaplanet-admin-panel >> diagnostic-output.txt

# Share diagnostic-output.txt for support
```

## Alternative: Use Different Port

If port 3200 continues to have issues, try a different port:

```bash
# Edit .env
echo "HTTP_PORT=8080" > .env
echo "HTTP_HOST=0.0.0.0" >> .env

# Recreate container
docker-compose down
docker-compose up -d

# Test
curl http://localhost:8080
```

## Network-Specific Issues

### Docker on Windows/Mac

Docker Desktop on Windows/Mac uses a VM, which can cause networking issues.

**Solution:**
1. Make sure Docker Desktop is running
2. Check Docker Desktop settings → Resources → Network
3. Try accessing via `host.docker.internal` instead of localhost
4. Consider using `network_mode: host` (not recommended for production)

### Accessing from Different Network

If accessing from a different network (not same LAN):
1. Configure port forwarding on your router
2. Use your public IP address
3. Consider security implications (use VPN or reverse proxy with HTTPS)

### Corporate/Restricted Networks

Some corporate networks block certain ports:
1. Try standard ports (8080, 8443)
2. Check with network administrator
3. Use VPN if available

## Summary

The most common issue is that `HTTP_HOST=0.0.0.0` is not set or the container wasn't recreated after changing `.env`. 

**Quick fix:**
```bash
echo "HTTP_PORT=3200" > .env
echo "HTTP_HOST=0.0.0.0" >> .env
docker-compose down
docker-compose up -d
sudo ufw allow 3200/tcp  # if firewall is active
```

Then access at `http://YOUR_IP:3200/`
