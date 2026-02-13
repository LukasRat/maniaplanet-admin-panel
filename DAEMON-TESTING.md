# Daemon Setup Testing Guide

This guide helps you verify that the admin panel is running correctly as a background daemon.

## Testing systemd Service

After installing with systemd, run these tests:

### 1. Check Service Status
```bash
sudo systemctl status maniaplanet-admin-panel
```
Expected output: `Active: active (running)`

### 2. Test Auto-Restart on Failure
```bash
# Get the PID
PID=$(systemctl show -p MainPID maniaplanet-admin-panel | cut -d'=' -f2)

# Kill the process
sudo kill $PID

# Wait a few seconds and check status
sleep 3
sudo systemctl status maniaplanet-admin-panel
```
Expected: Service should restart automatically

### 3. Test Health Endpoint
```bash
curl http://localhost:3100/health
```
Expected output: `{"status":"ok","uptime":123.456}`

### 4. View Logs
```bash
sudo journalctl -u maniaplanet-admin-panel -f
```

### 5. Test Boot Persistence
```bash
# Check if enabled for auto-start
systemctl is-enabled maniaplanet-admin-panel
```
Expected output: `enabled`

## Testing PM2 Setup

After starting with PM2, run these tests:

### 1. Check Process Status
```bash
pm2 status
```
Expected: `maniaplanet-admin-panel` should be listed with status `online`

### 2. Test Auto-Restart
```bash
# Get the PID
PID=$(pm2 jlist | jq '.[0].pid')

# Kill the process
kill $PID

# Check status after a few seconds
sleep 3
pm2 status
```
Expected: Process should restart with status `online` and restart count increased

### 3. Test Health Endpoint
```bash
curl http://localhost:3100/health
```
Expected output: `{"status":"ok","uptime":123.456}`

### 4. View Logs
```bash
pm2 logs maniaplanet-admin-panel
```

### 5. Test Monitoring
```bash
pm2 monit
```
Press `q` to exit

### 6. Check Boot Persistence
```bash
pm2 save
systemctl status pm2-$USER  # If using systemd integration
```

## Testing Docker Deployment

After starting with Docker Compose, run these tests:

### 1. Check Container Status
```bash
docker-compose ps
```
Expected: Container should be `Up`

### 2. Test Health Check
```bash
docker inspect maniaplanet-admin-panel | jq '.[0].State.Health'
```
Expected: `"Status": "healthy"`

### 3. Test Health Endpoint
```bash
curl http://localhost:3100/health
```
Expected output: `{"status":"ok","uptime":123.456}`

### 4. View Logs
```bash
docker-compose logs -f maniaplanet-admin-panel
```

### 5. Test Auto-Restart
```bash
# Stop the container
docker-compose stop maniaplanet-admin-panel

# Check if it restarts (unless-stopped policy)
docker-compose ps
```

### 6. Test Volume Mounts
```bash
# Check if maps directory is mounted
docker exec maniaplanet-admin-panel ls -la /server/UserData/Maps
```

## Common Issues and Solutions

### Issue: Service won't start
**Solution**: Check logs for error messages
```bash
# For systemd
sudo journalctl -u maniaplanet-admin-panel -n 50

# For PM2
pm2 logs maniaplanet-admin-panel --err

# For Docker
docker-compose logs maniaplanet-admin-panel
```

### Issue: Permission denied errors
**Solution**: Check file ownership and permissions
```bash
# For systemd
sudo ls -la /opt/maniaplanet-admin-panel

# Ensure the service user owns the files
sudo chown -R maniaplanet:maniaplanet /opt/maniaplanet-admin-panel
```

### Issue: Health check fails
**Solution**: Ensure the application is listening on the correct port
```bash
# Check if port 3100 is listening
netstat -tlnp | grep 3100
# or
ss -tlnp | grep 3100
```

### Issue: Can't connect to ManiaPlanet server
**Solution**: Verify RPC connection settings
1. Check server.js configuration (RPC_HOST, RPC_PORT)
2. Ensure ManiaPlanet server has XML-RPC enabled
3. Check firewall rules
4. Test connection: `telnet localhost 5000`

### Issue: Map uploads fail
**Solution**: Verify MAPS_DIR configuration
```bash
# For systemd - check environment variable
systemctl show maniaplanet-admin-panel | grep MANIAPLANET_MAPS_DIR

# For PM2 - check ecosystem.config.js
cat ecosystem.config.js | grep MANIAPLANET_MAPS_DIR

# For Docker - check docker-compose.yml
docker inspect maniaplanet-admin-panel | jq '.[0].Config.Env' | grep MANIAPLANET_MAPS_DIR
```

## Performance Testing

### Monitor Resource Usage

**systemd:**
```bash
systemctl status maniaplanet-admin-panel
```

**PM2:**
```bash
pm2 monit
```

**Docker:**
```bash
docker stats maniaplanet-admin-panel
```

### Load Testing
Test with multiple concurrent requests:
```bash
# Install Apache Bench if needed
# sudo apt-get install apache2-utils

# Test health endpoint
ab -n 1000 -c 10 http://localhost:3100/health
```

## Security Verification

### Check Service User Permissions (systemd)
```bash
# Verify service runs as non-root
ps aux | grep "node server.js"

# Check security settings
systemctl show maniaplanet-admin-panel | grep -E 'ProtectSystem|ProtectHome|PrivateTmp|NoNewPrivileges'
```

### Check Container Security (Docker)
```bash
# Verify container is not running as root
docker exec maniaplanet-admin-panel whoami

# Check security options
docker inspect maniaplanet-admin-panel | jq '.[0].HostConfig.SecurityOpt'
```

## Success Criteria

Your daemon setup is successful if:

- ✅ Service starts automatically on boot
- ✅ Service restarts automatically after crashes
- ✅ Health endpoint returns 200 OK
- ✅ Logs are accessible and readable
- ✅ Application survives terminal/SSH disconnection
- ✅ Resource usage is stable over time
- ✅ Maps can be uploaded successfully
- ✅ RPC connection to ManiaPlanet server works

## Next Steps

Once testing is complete:
1. Set up monitoring/alerting for the service
2. Configure log rotation to prevent disk space issues
3. Set up automated backups of configuration files
4. Document your specific deployment configuration
