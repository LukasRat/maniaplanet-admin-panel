# Port Configuration Troubleshooting Guide

This guide helps you troubleshoot port accessibility issues with the ManiaPlanet Admin Panel.

## Problem: Cannot Access Container on Custom Port

**Scenario:** You've set `HTTP_PORT=3200` in your `.env` file, but cannot access the admin panel at `http://192.168.178.43:3200/`

### Understanding How Ports Work

When you set `HTTP_PORT=3200` in `.env`, this affects:
1. The port the application listens on **inside** the container
2. The port Docker maps from the **host** to the container

The docker-compose.yml configuration:
```yaml
ports:
  - "${HTTP_PORT:-3100}:${HTTP_PORT:-3100}"
```

This means:
- **Left side (`${HTTP_PORT:-3100}`)**: Host port (accessible from outside)
- **Right side (`${HTTP_PORT:-3100}`)**: Container port (internal)
- Both use the same variable, so changing `HTTP_PORT` affects both

### Step-by-Step Solution

#### Step 1: Verify Your .env File

Make sure your `.env` file exists and contains:
```env
HTTP_PORT=3200
HTTP_HOST=0.0.0.0
```

**Common mistakes:**
- File named `.env.txt` instead of `.env`
- File in wrong directory (must be in same directory as `docker-compose.yml`)
- Typos in variable names

#### Step 2: Recreate the Container

**IMPORTANT:** You MUST recreate the container after changing `.env` variables.

```bash
# Stop and remove the container
docker-compose down

# Recreate with new configuration
docker-compose up -d
```

**Why this is necessary:**
- `docker-compose restart` does NOT reload environment variables
- `docker-compose up -d` without `down` may not recreate the container
- Only `down` followed by `up -d` ensures the new configuration is applied

#### Step 3: Verify Port Mapping

Check that Docker has correctly mapped the port:

```bash
docker ps
```

**Expected output:**
```
CONTAINER ID   IMAGE                    PORTS                    NAMES
abc123def456   maniaplanet-admin-panel  0.0.0.0:3200->3200/tcp   maniaplanet-admin-panel
```

**What to look for:**
- `0.0.0.0:3200->3200/tcp` means port 3200 is mapped correctly
- If you see `0.0.0.0:3100->3100/tcp`, the old configuration is still active (repeat Step 2)

#### Step 4: Check Container Logs

Verify the application is listening on the correct port:

```bash
docker logs maniaplanet-admin-panel
```

**Expected output:**
```
🚀 Maniaplanet Admin Panel Server Started!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Local:    http://localhost:3200
🌐 Network:  http://0.0.0.0:3200
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**What to look for:**
- Port number should match your `HTTP_PORT` setting
- If it shows `:3100`, the environment variable wasn't loaded (repeat Step 2)

#### Step 5: Test Local Access

Test if the container is accessible locally:

```bash
curl http://localhost:3200
```

or

```bash
curl http://127.0.0.1:3200
```

**Expected result:** HTML output from the admin panel

**If this fails:**
- Container might not be running: `docker ps`
- Application might have crashed: `docker logs maniaplanet-admin-panel`

#### Step 6: Test Network Access

If local access works but external access doesn't, this is a network/firewall issue.

**From another machine on the same network:**
```bash
curl http://192.168.178.43:3200
```

**If this fails, check:**

1. **Firewall on the Docker host:**
   - Linux (UFW): `sudo ufw allow 3200/tcp`
   - Linux (firewalld): `sudo firewall-cmd --add-port=3200/tcp --permanent && sudo firewall-cmd --reload`
   - Windows: Check Windows Defender Firewall settings

2. **Docker network mode:**
   - Ensure you're not using `network_mode: host` (our default config doesn't use this)
   - Check: `docker inspect maniaplanet-admin-panel | grep NetworkMode`

3. **Router/Network firewall:**
   - If accessing from a different network, check router port forwarding
   - Ensure no network-level firewall is blocking the port

### Quick Verification Checklist

Use this checklist to troubleshoot:

- [ ] `.env` file exists in the correct directory
- [ ] `.env` contains `HTTP_PORT=3200` (or your desired port)
- [ ] Ran `docker-compose down`
- [ ] Ran `docker-compose up -d`
- [ ] `docker ps` shows correct port mapping (0.0.0.0:3200->3200/tcp)
- [ ] `docker logs` shows application listening on port 3200
- [ ] `curl http://localhost:3200` returns HTML (local access works)
- [ ] Firewall allows incoming connections on port 3200
- [ ] Can access from external IP: `http://192.168.178.43:3200`

### Common Mistakes

#### Mistake 1: Using `restart` Instead of `down` + `up`

❌ **Wrong:**
```bash
docker-compose restart
```

✅ **Correct:**
```bash
docker-compose down
docker-compose up -d
```

#### Mistake 2: Wrong Port in Browser

❌ **Wrong:**
```
http://192.168.178.43:3100/  # Using old port
```

✅ **Correct:**
```
http://192.168.178.43:3200/  # Using new port from .env
```

#### Mistake 3: Forgetting to Save .env File

Make sure you save the `.env` file after editing it!

#### Mistake 4: Wrong File Name

❌ **Wrong:**
- `.env.txt`
- `env`
- `.environment`

✅ **Correct:**
- `.env` (exactly, with dot, no extension)

### Advanced Debugging

#### Check if Port is Listening

On the Docker host:
```bash
netstat -tlnp | grep 3200
```

or

```bash
ss -tlnp | grep 3200
```

**Expected output:**
```
tcp        0      0 0.0.0.0:3200            0.0.0.0:*               LISTEN      -
```

#### Check Docker Network

Inspect the container's network configuration:
```bash
docker inspect maniaplanet-admin-panel
```

Look for the `NetworkSettings` section and verify port mappings.

#### Test from Inside Container

Execute a shell inside the container and test:
```bash
docker exec -it maniaplanet-admin-panel sh
wget -O- http://localhost:3200
exit
```

If this works but external access doesn't, it's definitely a network/firewall issue.

### Still Not Working?

If you've followed all steps and it still doesn't work:

1. **Collect diagnostic information:**
   ```bash
   docker ps
   docker logs maniaplanet-admin-panel
   docker inspect maniaplanet-admin-panel | grep -A20 NetworkSettings
   cat .env
   ```

2. **Check for conflicting services:**
   ```bash
   netstat -tlnp | grep 3200
   ```
   Another service might be using the port.

3. **Try a different port:**
   Change `HTTP_PORT` to a different value (e.g., 8080) and repeat the process.

4. **Review Docker Compose configuration:**
   ```bash
   docker-compose config
   ```
   This shows the resolved configuration with environment variables applied.

## Network Access from External Networks

If you're trying to access the admin panel from outside your local network (e.g., from the internet):

1. **Configure port forwarding on your router:**
   - Forward external port (e.g., 3200) to internal IP (192.168.178.43) port 3200

2. **Use your public IP or domain:**
   ```
   http://your-public-ip:3200
   ```

3. **Security considerations:**
   - Consider using a reverse proxy (nginx, Traefik) with HTTPS
   - Implement authentication at the reverse proxy level
   - Use a VPN instead of exposing directly to the internet

## Related Documentation

- Main troubleshooting: See README.md "Troubleshooting" section
- Docker Compose configuration: See README.md "Using Docker Compose" section
- Environment variables: See `.env.example` for all available options
