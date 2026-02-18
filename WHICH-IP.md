# Which IP Address Do I Need to Use?

## Quick Answer

**Use your HOST machine's IP address, NOT the container's IP address.**

Example: If your host IP is `192.168.178.43` and you set `HTTP_PORT=3200`, access the admin panel at:
```
http://192.168.178.43:3200/
```

## Why Not the Container IP?

Docker containers have their own internal IP addresses (like `172.17.0.2`), but these are **only accessible from inside the Docker network**. When you want to access the admin panel from your web browser, you need to use the **host machine's IP address** because Docker maps the container's internal port to the host's external port.

## Visual Explanation

```
┌─────────────────────────────────────────────────────────┐
│ Your Computer/Browser                                    │
│                                                          │
│  Type in browser: http://192.168.178.43:3200/          │
│                            ↓                             │
└────────────────────────────┼────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────┐
│ Host Machine (192.168.178.43)                           │
│                             ↓                            │
│  Port 3200 on host ────────┼────────────────┐          │
│                             ↓                 │          │
│  ┌──────────────────────────────────────┐   │          │
│  │ Docker Container                      │   │          │
│  │ Internal IP: 172.17.0.2 (not used!)  │   │          │
│  │ Listening on: 0.0.0.0:3200           │◄──┘          │
│  │ (mapped to host port 3200)           │              │
│  └──────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────┘
```

## How to Find Your Host IP Address

### Method 1: Use the Diagnostic Script
```bash
./diagnose-port.sh 3200
```

Look for the "Checking network interfaces" section - it will show your IP addresses.

### Method 2: Command Line

**Linux/Mac:**
```bash
# Option 1: Using ip command
ip addr show | grep "inet " | grep -v "127.0.0.1"

# Option 2: Using hostname
hostname -I | awk '{print $1}'

# Option 3: Using ifconfig
ifconfig | grep "inet " | grep -v "127.0.0.1"
```

**Windows (PowerShell):**
```powershell
ipconfig | findstr IPv4
```

**Windows (Command Prompt):**
```cmd
ipconfig
```

### Method 3: Quick One-Liner
```bash
# This will show only your primary IP
hostname -I | awk '{print $1}'
```

## Different Scenarios

### Scenario 1: Accessing from Same Machine

**Use localhost:**
```
http://localhost:3200/
```

This works because you're accessing from the same machine where Docker is running.

### Scenario 2: Accessing from Another Computer on Same Network

**Use host IP:**
```
http://192.168.178.43:3200/
```

Replace `192.168.178.43` with your actual host machine IP address.

### Scenario 3: Accessing from the Internet

**Use public IP or domain:**
```
http://your-public-ip:3200/
```

**Important:** You'll need to:
1. Configure port forwarding on your router
2. Use your public IP address (not 192.168.x.x)
3. Consider security implications (use HTTPS, VPN, etc.)

## Common Mistakes

### ❌ Mistake 1: Using Container IP
```
# WRONG - This won't work from your browser
http://172.17.0.2:3200/
```

Container IPs are only accessible from inside Docker's internal network.

### ❌ Mistake 2: Using 0.0.0.0
```
# WRONG - 0.0.0.0 is not a valid IP to connect to
http://0.0.0.0:3200/
```

`0.0.0.0` means "listen on all interfaces" - it's a configuration value, not an address you can connect to.

### ❌ Mistake 3: Using 127.0.0.1 from Another Computer
```
# WRONG - Only works from the same machine
http://127.0.0.1:3200/
```

`127.0.0.1` (localhost) only works when accessing from the same machine.

### ✅ Correct: Using Host IP
```
# CORRECT - Works from any computer on your network
http://192.168.178.43:3200/
```

## Quick Check Commands

### Get Your Host IP
```bash
# Quick command to show your IP
hostname -I | awk '{print $1}'
```

### Get the Full URL to Use
```bash
# This shows the exact URL you should use
PORT=3200
IP=$(hostname -I | awk '{print $1}')
echo "Access the admin panel at: http://$IP:$PORT/"
```

### Check if Port is Accessible
```bash
# Test from same machine
curl http://localhost:3200

# Test from another machine (replace IP)
curl http://192.168.178.43:3200
```

## Understanding the Port Mapping

When Docker Compose starts with this configuration:
```yaml
ports:
  - "3200:3200"
```

It means:
- **Left side (3200)**: Port on **HOST** machine - this is what you connect to
- **Right side (3200)**: Port inside **CONTAINER** - this is what the app uses internally

The mapping creates a "tunnel" from host port 3200 to container port 3200.

## Your Current Issue

Based on your diagnostic output:
```
3. Checking Docker port mapping...
   ✗ ERROR: Port 3200 is NOT mapped correctly!
     Current mapping: 3100/tcp,
     Action needed: docker-compose down && docker-compose up -d
```

**Problem:** The container is still using port 3100, not 3200.

**Solution:**
```bash
# Step 1: Stop and remove the old container
docker-compose down

# Step 2: Start with new configuration (will use 3200)
docker-compose up -d

# Step 3: Wait a few seconds
sleep 5

# Step 4: Get your host IP
IP=$(hostname -I | awk '{print $1}')

# Step 5: Show the URL to use
echo ""
echo "================================================"
echo "Access your admin panel at:"
echo "http://$IP:3200/"
echo "or from same machine:"
echo "http://localhost:3200/"
echo "================================================"
```

## Summary

| Scenario | IP to Use | Example |
|----------|-----------|---------|
| From same machine | `localhost` or `127.0.0.1` | `http://localhost:3200/` |
| From another computer (same network) | Host IP | `http://192.168.178.43:3200/` |
| From the internet | Public IP + port forwarding | `http://YOUR_PUBLIC_IP:3200/` |
| **NEVER use** | Container IP | ~~`http://172.17.0.2:3200/`~~ |
| **NEVER use** | 0.0.0.0 | ~~`http://0.0.0.0:3200/`~~ |

## Still Confused?

Run this command to see exactly what URL to use:
```bash
./show-access-url.sh
```

This will detect your IP and show you the exact URL to paste into your browser.
