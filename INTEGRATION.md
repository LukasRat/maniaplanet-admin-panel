# Integration Guide: Connecting to Existing ManiaPlanet Server

This guide helps you integrate the ManiaPlanet Admin Panel with an existing ManiaPlanet dedicated server running in Docker.

## Prerequisites

- Existing ManiaPlanet dedicated server running in Docker
- XML-RPC enabled on the dedicated server (port 5000)
- Docker and Docker Compose installed
- Access to the server's Maps directory

## Quick Setup

### Step 1: Create Configuration File

```bash
cp .env.example .env
```

### Step 2: Edit .env File

Edit the `.env` file with your server details:

```env
# Application Configuration
HTTP_PORT=3100

# ManiaPlanet Server Connection
RPC_HOST=dedicated_stadium        # Your dedicated server container name
RPC_PORT=5000                     # XML-RPC port (usually 5000)
RPC_LOGIN=SuperAdmin              # SuperAdmin login

# Maps Directory
MANIAPLANET_MAPS_DIR=/maps        # Internal container path
MAPS_PATH=./Maps/                 # Host path (must match your server's Maps directory)
```

### Step 3: Choose Deployment Method

#### Option A: Admin Panel Only (Existing Server)

If your server is already running, use the standalone configuration:

```bash
docker-compose -f docker-compose.standalone.yml up -d
```

#### Option B: Complete Setup (New Deployment)

To deploy everything together (admin panel + dedicated server + expansion):

```bash
docker-compose up -d
```

### Step 4: Verify Network Connectivity

Ensure the admin panel can communicate with your dedicated server:

```bash
# Check if both containers are on the same network
docker network inspect xmlrpc-network

# Expected: Both maniaplanet-admin-panel and dedicated_stadium should appear
```

If the network doesn't exist, create it:

```bash
docker network create xmlrpc-network
```

### Step 5: Access the Admin Panel

Open your browser and navigate to:
```
http://localhost:3100
```

Enter your ManiaPlanet SuperAdmin password to log in.

## Troubleshooting

### Cannot Connect to Server

**Problem:** Admin panel shows "Could not connect to Game Server"

**Solutions:**
1. Verify both containers are on the same network:
   ```bash
   docker network inspect xmlrpc-network
   ```

2. Check the RPC_HOST setting in your `.env` file matches your dedicated server's container name:
   ```bash
   docker ps | grep dedicated
   ```

3. Verify XML-RPC is enabled on your dedicated server (check dedicated server config)

4. Check if the dedicated server is running:
   ```bash
   docker ps | grep dedicated_stadium
   ```

### Map Uploads Not Working

**Problem:** Maps upload but don't appear in the server

**Solutions:**
1. Ensure `MAPS_PATH` in `.env` points to the same directory as your dedicated server
2. Verify the admin panel has write permissions to the Maps directory
3. Check the mounted volume paths match:
   ```bash
   docker inspect maniaplanet-admin-panel | grep -A5 Mounts
   docker inspect dedicated_stadium | grep -A5 Mounts
   ```

### Network Not Found

**Problem:** `Error: network xmlrpc-network declared as external, but could not be found`

**Solution:**
```bash
docker network create xmlrpc-network
```

## Example Configuration for skorlok/expansion

If you're using the `ghcr.io/skorlok/expansion` images, your setup should look like this:

### Directory Structure
```
your-project/
├── docker-compose.yml        # Main configuration (provided)
├── .env                      # Your environment configuration
├── Maps/                     # Shared maps directory
├── Config/                   # Server configuration
├── eXpConfig/               # Expansion configuration
└── Backups/                 # Backup directory
```

### .env Configuration
```env
# Admin Panel
HTTP_PORT=3100
HTTP_HOST=0.0.0.0

# Server Connection
RPC_HOST=dedicated_stadium
RPC_PORT=5000
RPC_LOGIN=SuperAdmin

# Maps (relative to docker-compose.yml)
MAPS_PATH=./Maps/
MANIAPLANET_MAPS_DIR=/maps
```

### Start Everything
```bash
# Start all services (dedicated server + expansion + admin panel)
docker-compose up -d

# View logs
docker-compose logs -f maniaplanet-admin-panel

# Stop all services
docker-compose down
```

## Additional Resources

- ManiaPlanet Admin Panel Documentation: See README.md
- Docker Networking: https://docs.docker.com/network/
- skorlok/expansion Images: https://github.com/skorlok/maniaplanet-docker

## Support

If you encounter issues:
1. Check the admin panel logs: `docker logs maniaplanet-admin-panel`
2. Check the dedicated server logs: `docker logs dedicated_stadium`
3. Verify network connectivity: `docker network inspect xmlrpc-network`
4. Review the troubleshooting section above
