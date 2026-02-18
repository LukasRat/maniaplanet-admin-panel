# Quick Reference: Accessing Your Admin Panel

## 🎯 The Short Answer

**Use your HOST machine's IP address, not the container IP!**

### From the Same Computer
```
http://localhost:3200
```

### From Another Computer
```
http://192.168.x.x:3200
```
*(Replace with your actual host IP)*

---

## 🔍 Find Your Host IP

### Linux/Mac
```bash
hostname -I | awk '{print $1}'
```

### Or use the helper script
```bash
./show-access-url.sh
```

---

## ❌ Common Mistakes

| ❌ Wrong | ✅ Right | Why |
|----------|----------|-----|
| `http://172.17.0.2:3200` | `http://192.168.1.100:3200` | Container IP vs Host IP |
| `http://0.0.0.0:3200` | `http://192.168.1.100:3200` | 0.0.0.0 is not a valid address |
| `http://127.0.0.1:3200` (from another PC) | `http://192.168.1.100:3200` | 127.0.0.1 only works locally |

---

## 📋 Common Issues

### Issue 1: Connection Refused
**Symptom:** Container runs but can't connect

**Check:**
```bash
docker logs --tail 30 maniaplanet-admin-panel
```

**Fix:**
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

**See:** [CONNECTION-REFUSED.md](CONNECTION-REFUSED.md)

---

### Issue 2: Wrong Port
**Problem:** Container is using port 3100, but .env says 3200

**Fix:**
```bash
docker-compose down
docker-compose up -d
```

**If that doesn't work (persistent issue):**
```bash
./reset-port.sh 3200
```

**See:** [PERSISTENT-PORT-ISSUE.md](PERSISTENT-PORT-ISSUE.md)

**Then access at:**
- Local: `http://localhost:3200`
- Network: `http://YOUR_HOST_IP:3200`

---

## 🔧 Complete Fix Commands

```bash
# 1. Ensure .env has both settings
cat > .env << 'EOF'
HTTP_PORT=3200
HTTP_HOST=0.0.0.0
RPC_HOST=dedicated_stadium
RPC_PORT=5000
RPC_LOGIN=SuperAdmin
MANIAPLANET_MAPS_DIR=/maps
MAPS_PATH=./Maps/
EOF

# 2. Recreate container
docker-compose down
docker-compose up -d

# 3. Wait for startup
sleep 5

# 4. Show access URL
./show-access-url.sh

# 5. Test local access
curl http://localhost:3200
```

---

## 📖 More Information

- **Detailed guide:** [WHICH-IP.md](WHICH-IP.md)
- **External access:** [EXTERNAL-ACCESS.md](EXTERNAL-ACCESS.md)
- **Port issues:** [PORT-TROUBLESHOOTING.md](PORT-TROUBLESHOOTING.md)
- **Diagnostic tool:** `./diagnose-port.sh 3200`

---

## 💡 Remember

1. **Host IP** = Your computer's IP on the network
2. **Container IP** = Docker's internal IP (don't use this!)
3. **Port** = The number you set in HTTP_PORT
4. **Must recreate** container after changing .env

---

## 🆘 Still Having Issues?

Run the diagnostic:
```bash
./diagnose-port.sh 3200
```

This will check:
- ✓ .env configuration
- ✓ Container status
- ✓ Port mapping
- ✓ Firewall
- ✓ Network interfaces
- ✓ And show you the exact URL to use!
