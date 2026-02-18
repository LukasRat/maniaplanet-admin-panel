# ManiaPlanet Admin Panel Modernized

A sleek, modern, and powerful web-based admin panel for ManiaPlanet game servers (Stadium).

![Dashboard][dashboard-screenshot]

## Features

- 🌑 **Modern UI:** Dark theme with glassmorphism and neon accents.
- 📊 **Real-time Dashboard:** Live overview of server status, map info, and players.
- 🏎️ **Map Management:** Drag-and-drop map uploads, pool shuffling, and removal.
- 👥 **Player Controls:** Kick, Ban, Mute, or Spectate players directly from the UI.
- 🕒 **Live Rankings:** Real-time session rankings with accurate best times.
- 💬 **Integrated Chat:** Full server chat integration with ManiaPlanet formatting support.
- 🎨 **Clean Display:** Automatically strips ManiaPlanet color codes from names for clean, readable text.
- 🔄 **Server Controls:** Restart server, restart map, skip map, and shuffle map pool.
- ⚡ **Expansion Support:** Dedicated restart functionality for ManiaPlanet expansion/controller.

## UI Overview

The admin panel features a modern, intuitive interface with multiple sections:

### 🎯 Dashboard
Real-time overview showing:
- **Players Online** - Current player count
- **Maps in Pool** - Total maps available
- **Current Map** - Active map being played

![Dashboard][dashboard-screenshot]

### 🎮 Server Management
Complete server control including:
- **Skip Map** - Move to the next map in rotation
- **Restart Map** - Restart the current map
- **Shuffle Maps** - Randomize the map pool order
- **Restart Server** - Full server restart (requires configuration)
- **Restart Expansion** - Restart the ManiaPlanet expansion/controller

Server information display:
- Server name (with clean formatting)
- Version information
- Maximum players and spectators

### 👥 Player Management
Full player control capabilities:
- **Kick** - Remove player from server
- **Ban** - Permanently ban a player
- **Spectate** - Force player to spectator mode
- View player nicknames with clean formatting (color codes automatically stripped)

### 🗺️ Map Pool Management
Advanced map management features:
- View all maps in the current pool
- **Queue Maps** - Set next map to play
- **Remove Maps** - Delete maps from rotation
- See which map is currently active
- Identify maps not in pool vs. maps only in pool

### 🏆 Live Rankings
Real-time leaderboard showing:
- Player positions (top 3 highlighted)
- Best lap times
- Player names with clean formatting

### 💬 Server Chat
Integrated chat system:
- View all server messages
- Send server-wide messages
- Automatic ManiaPlanet formatting code handling

### ☁️ Map Upload
Drag-and-drop map upload:
- Multi-file upload support
- Automatic `.gbx` file detection
- Direct integration with map pool
- Upload status feedback

## 🎨 ManiaPlanet Color Code Support

The admin panel automatically strips ManiaPlanet formatting codes from all displayed text, ensuring clean and readable names throughout the interface.

ManiaPlanet uses special formatting codes like:
- `$F00` - Color codes (hex colors)
- `$o` - Bold text
- `$i` - Italic text
- `$w` - Wide text
- `$n` - Narrow text
- And many more...

The panel intelligently removes these codes from:
- ✅ Server names
- ✅ Player nicknames
- ✅ Map names
- ✅ Chat messages

This ensures a clean, professional appearance while maintaining full compatibility with ManiaPlanet's formatting system.

## Tech Stack

- **Backend:** Node.js, Express, `gbxremote` (XML-RPC).
- **Frontend:** Vanilla HTML5, CSS3, ES6 JavaScript.

## Getting Started

### Prerequisites

- Node.js 20+
- A running ManiaPlanet 4 Stadium server with XML-RPC enabled (Port 5000).

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/LukasRat/maniaplanet-admin-panel.git
   cd maniaplanet-admin-panel
   ```

2. **Install dependencies** (⚠️ Required - do not skip this step):
   ```bash
   npm install
   ```
   > **Note:** This installs Express, gbxremote, and other required packages. If you skip this step, you'll get "Cannot find module 'express'" errors.

3. **Configure your server** - Edit `server.js` and update the constants at the top:
   
   **RPC Connection Settings:**
   ```javascript
   const RPC_HOST = '127.0.0.1';
   const RPC_PORT = 5000;
   const RPC_LOGIN = 'SuperAdmin';
   ```
   
   **⚠️ CRITICAL: Maps Directory Configuration**
   
   You **MUST** configure `MAPS_DIR` to point to your Maniaplanet server's actual UserData/Maps directory:
   
   ```javascript
   const MAPS_DIR = '/home/user/Desktop/maniaplanetserver/UserData/Maps'
   ```
   
   **Platform-specific examples:**
   - Linux: `/home/user/Desktop/maniaplanetserver/UserData/Maps`
   - Windows: `C:\\ManiaPlanetServer\\UserData\\Maps`
   - Docker: `/server/UserData/Maps` (mount the server's Maps directory)
   
   **Using environment variable:**
   ```bash
   export MANIAPLANET_MAPS_DIR="/home/user/Desktop/maniaplanetserver/UserData/Maps"
   npm start
   ```
   
   **Important requirements:**
   - Path must point to where your Maniaplanet server actually stores maps
   - Admin panel must have write permissions to this directory
   - Map files will be saved directly to this location
   - If path is wrong, map uploads will fail with "Map unknown" errors

4. Start the panel:
   ```bash
   npm start
   ```

5. Access the panel:
   - From same machine: `http://localhost:3100`
   - From another computer: `http://YOUR_HOST_IP:3100`
   
   > **Need your IP?** Run `hostname -I | awk '{print $1}'`
   
   Enter your ManiaPlanet server password to login.

### Docker Installation (Alternative)

If you prefer using Docker, you can run the admin panel in a containerized environment:

> **Important:** When using Docker, you access the panel using your **host machine's IP address**, not the container's internal IP. See [WHICH-IP.md](WHICH-IP.md) for details.

#### Quick Start with Docker

1. **Clone the repository:**
   ```bash
   git clone https://github.com/LukasRat/maniaplanet-admin-panel.git
   cd maniaplanet-admin-panel
   ```

2. **Build the Docker image:**
   ```bash
   docker build -t maniaplanet-admin-panel .
   ```

3. **Run the container:**
   
   **On Linux (recommended - allows connection to localhost):**
   ```bash
   docker run -d \
     --name maniaplanet-admin-panel \
     --network host \
     -e MANIAPLANET_MAPS_DIR=/maps \
     -v /path/to/your/maniaplanet/UserData/Maps:/maps \
     maniaplanet-admin-panel
   ```
   
   **On Windows/Mac (or without host network):**
   ```bash
   docker run -d \
     --name maniaplanet-admin-panel \
     -p 3100:3100 \
     -e HTTP_PORT=3100 \
     -e RPC_HOST=host.docker.internal \
     -e MANIAPLANET_MAPS_DIR=/maps \
     -v /path/to/your/maniaplanet/UserData/Maps:/maps \
     maniaplanet-admin-panel
   ```
   > **Note**: On Windows/Mac, you can use `host.docker.internal` to connect to services on your host machine, or use your host machine's IP address for `RPC_HOST`.
   
   **Important**: Replace `/path/to/your/maniaplanet/UserData/Maps` with the actual path to your ManiaPlanet server's Maps directory.

4. **Access the panel:**
   Open `http://localhost:3100` in your browser and enter your ManiaPlanet server password to login.

#### Using Docker Compose (Recommended)

For easier management, use Docker Compose:

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```
   
   > **Important:** The file must be named exactly `.env` (with a dot at the beginning, no extension). This is the standard convention that Docker Compose automatically reads. Do NOT name it `.env.txt`, `env`, or anything else.

2. **Edit `.env` to configure your setup** (optional, defaults work for most cases):
   ```env
   # Application ports
   HTTP_PORT=3100
   HTTP_HOST=0.0.0.0    # IMPORTANT: Must be 0.0.0.0 for external access!
   
   # ManiaPlanet server connection
   RPC_HOST=127.0.0.1
   RPC_PORT=5000
   
   # Maps directory
   MANIAPLANET_MAPS_DIR=/maps
   ```
   
   > **Critical for External Access:** If you want to access the admin panel from your web browser or another computer, you MUST set `HTTP_HOST=0.0.0.0`. Without this, the application will only be accessible from inside the container.

3. **Start the service:**
   ```bash
   docker-compose up -d
   ```

4. **Find your access URL:**
   ```bash
   # Quick helper to show exactly which URL to use
   ./show-access-url.sh
   
   # Or manually find your IP:
   hostname -I | awk '{print $1}'
   ```
   
   > **Which IP to Use?** Use your **HOST machine's IP** (not the container IP). See [WHICH-IP.md](WHICH-IP.md) for detailed explanation.
   
   **Access from:**
   - Same machine: `http://localhost:3100`
   - Other computers: `http://YOUR_HOST_IP:3100`

5. **View logs:**
   ```bash
   docker-compose logs -f
   ```

6. **Stop the service:**
   ```bash
   docker-compose down
   ```

7. **Changing configuration (e.g., ports):**
   
   > **Important:** After changing values in `.env` (like `HTTP_PORT`), you must recreate the container:
   
   ```bash
   # Stop and remove the container
   docker-compose down
   
   # Recreate with new configuration
   docker-compose up -d
   ```
   
   **Note:** Simply using `docker-compose restart` will NOT reload environment variables from `.env`. You must use `down` followed by `up -d`.

#### Integrating with Existing ManiaPlanet Server (Docker)

If you already have a ManiaPlanet dedicated server running in Docker (e.g., using `ghcr.io/skorlok/expansion`), you can integrate the admin panel with it:

1. **Use the standalone configuration:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your server configuration:**
   ```env
   # Set RPC_HOST to your dedicated server container name
   RPC_HOST=dedicated_stadium
   
   # Set the Maps path to match your server's Maps directory
   MAPS_PATH=./Maps/
   
   # Other settings (use defaults if unsure)
   HTTP_PORT=3100
   RPC_PORT=5000
   RPC_LOGIN=SuperAdmin
   ```

3. **Option A: Use the full docker-compose.yml**
   
   The main `docker-compose.yml` includes your complete setup (admin panel + dedicated server + expansion).
   Simply run:
   ```bash
   docker-compose up -d
   ```

4. **Option B: Use standalone configuration (if server is already running)**
   
   If your dedicated server is already running separately:
   ```bash
   docker-compose -f docker-compose.standalone.yml up -d
   ```

5. **Network Requirements:**
   - The admin panel must be on the same Docker network as your dedicated server
   - Default network name: `xmlrpc-network`
   - If the network doesn't exist, create it:
     ```bash
     docker network create xmlrpc-network
     ```
   - Ensure your dedicated server container is connected to this network

6. **Verify the connection:**
   ```bash
   # Check if containers are on the same network
   docker network inspect xmlrpc-network
   
   # View admin panel logs
   docker logs maniaplanet-admin-panel
   ```

**Key Configuration Points:**
- `RPC_HOST` should be set to your dedicated server's container name (e.g., `dedicated_stadium`)
- `MAPS_PATH` should point to the same directory your dedicated server uses for maps
- Both containers must be on the same Docker network for XML-RPC communication
- The dedicated server's XML-RPC must be enabled (usually on port 5000)

#### Docker Configuration Notes

- **Network Mode**: Use `--network host` (Linux) to allow the container to access the ManiaPlanet server on `127.0.0.1:5000`.
  - On Windows/Mac, use the host's IP address instead of `127.0.0.1` and update `RPC_HOST` environment variable.
- **Maps Directory**: The container needs access to your ManiaPlanet server's Maps directory for map uploads to work.
- **Environment Variables**:
  - `HTTP_PORT`: Port for the admin panel web interface (default: `3100`)
  - `HTTP_HOST`: Host to bind the HTTP server (default: `0.0.0.0`)
  - `RPC_HOST`: XML-RPC host of your ManiaPlanet server (default: `127.0.0.1`)
  - `RPC_PORT`: XML-RPC port of your ManiaPlanet server (default: `5000`)
  - `RPC_LOGIN`: XML-RPC login for SuperAdmin access (default: `SuperAdmin`)
  - `MANIAPLANET_MAPS_DIR`: Path inside the container where maps are stored (default: `/maps`)

#### Configuring Custom Ports

You can customize the ports using environment variables:

**Using Docker run:**
```bash
docker run -d \
  --name maniaplanet-admin-panel \
  -p 8080:8080 \
  -e HTTP_PORT=8080 \
  -e RPC_PORT=5001 \
  -e MANIAPLANET_MAPS_DIR=/maps \
  -v /path/to/your/maniaplanet/UserData/Maps:/maps \
  maniaplanet-admin-panel
```

**Using Docker Compose:**

Create a `.env` file in the same directory as `docker-compose.yml`:
```bash
cp .env.example .env
# Then edit .env with your values
```

Example `.env` content:
```env
HTTP_PORT=8080
RPC_HOST=192.168.1.100
RPC_PORT=5001
```

Then run:
```bash
docker-compose up -d
```

> **Note:** The file must be named `.env` (exactly) for Docker Compose to automatically read it.

#### Publishing and Using Pre-built Docker Images

**Building and Tagging for Docker Hub:**

1. **Build the image with a tag:**
   ```bash
   docker build -t yourusername/maniaplanet-admin-panel:latest .
   docker build -t yourusername/maniaplanet-admin-panel:v1.0.0 .
   ```

2. **Login to Docker Hub:**
   ```bash
   docker login
   ```

3. **Push the image:**
   ```bash
   docker push yourusername/maniaplanet-admin-panel:latest
   docker push yourusername/maniaplanet-admin-panel:v1.0.0
   ```

**Using a Pre-built Image:**

If a pre-built image is available on Docker Hub:
```bash
docker pull yourusername/maniaplanet-admin-panel:latest
docker run -d \
  --name maniaplanet-admin-panel \
  -p 3100:3100 \
  -e MANIAPLANET_MAPS_DIR=/maps \
  -v /path/to/your/maniaplanet/UserData/Maps:/maps \
  yourusername/maniaplanet-admin-panel:latest
```

**Building from Source:**

To build the image locally from the repository:
```bash
git clone https://github.com/LukasRat/maniaplanet-admin-panel.git
cd maniaplanet-admin-panel
docker build -t maniaplanet-admin-panel .
```

#### Automated Docker Image Publishing with GitHub Actions

The repository includes a GitHub Actions workflow (`.github/workflows/docker-publish.yml`) that automatically builds and publishes Docker images to Docker Hub.

**Setup:**

1. **Create Docker Hub secrets in your GitHub repository:**
   - Go to your repository settings → Secrets and variables → Actions
   - Add `DOCKER_USERNAME`: Your Docker Hub username
   - Add `DOCKER_PASSWORD`: Your Docker Hub access token (not your password - create one at https://hub.docker.com/settings/security)

2. **The workflow will automatically:**
   - Build images on every push to main/master branch
   - Build images for pull requests (without pushing)
   - Tag images with version numbers when you create a release tag (e.g., `v1.0.0`)
   - Build multi-platform images (amd64 and arm64)
   - Push to Docker Hub with appropriate tags (latest, version numbers, branch names)

3. **Create a release:**
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

The workflow will automatically build and push the image with tags: `latest`, `v1.0.0`, `1.0`, and `1`.

### Configuring Server Restart (Required for Restart Button)

⚠️ **IMPORTANT**: The "Restart Server" button will NOT work until you configure `restart.sh` for your specific server setup!

The admin panel includes a server restart feature that uses the `restart.sh` script. **By default, this script is NOT configured and will fail.** You must edit it to match your server installation.

#### Quick Setup

1. **Open the restart.sh file:**
   ```bash
   nano restart.sh
   ```

2. **Find the method that matches your setup and uncomment it:**

   **If you use systemd (most common):**
   ```bash
   # Uncomment this line (remove the #):
   sudo systemctl restart maniaplanet-server
   ```

   **If you use screen/tmux:**
   ```bash
   # Uncomment and configure these lines:
   SCREEN_NAME="maniaplanet"
   screen -S "$SCREEN_NAME" -X quit
   sleep 2
   screen -dmS "$SCREEN_NAME" /path/to/ManiaPlanetServer /dedicated_cfg=your_config.txt
   ```

   **If you use Docker:**
   ```bash
   # Uncomment and configure:
   CONTAINER_NAME="maniaplanet-server"
   docker restart "$CONTAINER_NAME"
   ```

   **If you have a custom script:**
   ```bash
   # Add your restart command in Method 6:
   /path/to/your/restart_script.sh
   exit 0
   ```

3. **Make the script executable:**
   ```bash
   chmod +x restart.sh
   ```

4. **Test the script manually** before using it through the UI:
   ```bash
   ./restart.sh
   ```
   
   If you see "ERROR: No restart method configured!", you need to uncomment one of the methods in the script.

5. **Test through the admin panel** - Click "Restart Server" and check:
   - The server console for script output
   - Whether your ManiaPlanet server actually restarts
   - If it fails, check the browser console (F12) for error details

#### Common Issues

- **"Only npm gets stopped"** - The script isn't configured. Edit restart.sh and uncomment your restart method.
- **Permission denied** - The script may need sudo. Either configure passwordless sudo or add `sudo` before the restart command.
- **Script not found** - Make sure restart.sh is in the same directory as server.js and is executable.

> **Note:** The admin panel (Node.js) runs separately from your ManiaPlanet game server. This script restarts the **game server**, not the admin panel.

### Configuring Expansion Restart (Optional)

If you use a ManiaPlanet expansion or controller (a separate process that manages server modes, plugins, or advanced features), you can configure the expansion restart feature:

1. **Edit the restart_expansion.sh file:**
   ```bash
   nano restart_expansion.sh
   ```

2. **Configure the expansion directory path:**
   ```bash
   EXPANSION_DIR="/home/user/Desktop/expansion"
   ```
   Update this to point to your actual expansion installation directory.

3. **Make the script executable:**
   ```bash
   chmod +x restart_expansion.sh
   ```

4. **Test the script:**
   ```bash
   ./restart_expansion.sh
   ```

The script will:
- Stop the expansion using `./run --stop`
- Wait 10 seconds
- Start the expansion using `./run --start`

> **Note:** This feature is optional and only needed if you run a ManiaPlanet expansion/controller alongside your game server.

## Troubleshooting

### Map Upload Not Working

If map uploads fail or show "0 maps uploaded":

1. **⚠️ Check MAPS_DIR configuration (MOST COMMON ISSUE)**:
   - Open `server.js` and find the `MAPS_DIR` constant (around line 33)
   - It **MUST** point to your actual Maniaplanet server's UserData/Maps directory
   - Default value `/home/user/Desktop/maniaplanetserver/UserData/Maps` is just an example!
   - Change it to match YOUR server installation path
   
   Example for different setups:
   ```javascript
   // Linux home directory
   const MAPS_DIR = '/home/yourname/maniaplanet-server/UserData/Maps'
   
   // Windows
   const MAPS_DIR = 'C:\\ManiaPlanetServer\\UserData\\Maps'
   
   // Docker (with volume mount)
   const MAPS_DIR = '/server/UserData/Maps'
   ```

2. **Verify the directory exists and is writable**:
   ```bash
   # Check if directory exists
   ls -la /path/to/your/ManiaPlanetServer/UserData/Maps
   
   # Check permissions
   ls -ld /path/to/your/ManiaPlanetServer/UserData/Maps
   
   # Make it writable if needed
   chmod 755 /path/to/your/ManiaPlanetServer/UserData/Maps
   ```

3. **Check for common errors**:
   - **"Map unknown"** - MAPS_DIR is wrong, file not in server's Maps directory
   - **"couldn't write file"** - Permission denied or path doesn't exist
   - **"0 maps uploaded"** - Files saved locally but MAPS_DIR not pointing to server
   
4. **Test the configuration**:
   - Upload a test map
   - Check if the file appears in your server's UserData/Maps directory
   - If not, MAPS_DIR is configured incorrectly

**How it works:**
- Admin panel saves map files directly to the server's Maps directory
- Then calls AddMap RPC to register them
- Requires the admin panel to have filesystem access to the server

### Error: Cannot find module 'express'

If you see this error when running `npm start`:
```
Error: Cannot find module 'express'
```

**Solution:** You need to install dependencies first:
```bash
npm install
```

This happens because `node_modules/` is not included in the repository (it's in `.gitignore`). You must run `npm install` to download all required packages before starting the server.

### Other Common Issues

- **Server won't connect:** Ensure your ManiaPlanet server is running with XML-RPC enabled on the correct port (default: 5000). Use `RPC_HOST` and `RPC_PORT` environment variables to configure connection.
- **Port already in use:** Change `HTTP_PORT` environment variable to use a different port. For Docker: `-e HTTP_PORT=8080 -p 8080:8080`
- **Environment variables not loading:** Make sure your configuration file is named exactly `.env` (not `.env.txt`, `env`, or anything else). Use `cp .env.example .env` to create it properly.

### Application Not Accessible from Outside Container

**Problem:** Cannot access the admin panel from your web browser or another computer, even after setting the port correctly.

**Quick Diagnostic:** Run the diagnostic script:
```bash
./diagnose-port.sh 3200
```

**Common causes:**
1. Container not recreated after changing `.env` (must use `down` then `up -d`)
2. `HTTP_HOST` not set to `0.0.0.0` (required for external access)
3. Firewall blocking the port
4. Port mapping using `127.0.0.1` instead of `0.0.0.0`

**Quick fix:**
```bash
# Ensure .env has correct settings
echo "HTTP_PORT=3200" > .env
echo "HTTP_HOST=0.0.0.0" >> .env

# Recreate container
docker-compose down
docker-compose up -d

# Allow through firewall (if active)
sudo ufw allow 3200/tcp

# Verify
docker ps  # Should show 0.0.0.0:3200->3200/tcp
```

**📖 See detailed guide:** [EXTERNAL-ACCESS.md](EXTERNAL-ACCESS.md) for complete troubleshooting steps.

### Custom Port Not Accessible

**Problem:** Container not accessible on custom port (e.g., `http://192.168.178.43:3200/`) after setting `HTTP_PORT=3200` in `.env`

**Cause:** Docker containers must be recreated after changing environment variables in `.env` file.

**Solution:**

1. **Stop and remove the existing container:**
   ```bash
   docker-compose down
   ```

2. **Recreate the container with new port configuration:**
   ```bash
   docker-compose up -d
   ```
   
   **Important:** Use `down` and then `up -d`, NOT just `restart`. The `restart` command does not reload environment variables from `.env`.

3. **Verify the port mapping:**
   ```bash
   docker ps
   ```
   
   Look for the port mapping in the output. You should see something like:
   ```
   0.0.0.0:3200->3200/tcp
   ```

4. **Check if the container is listening on the correct port:**
   ```bash
   docker logs maniaplanet-admin-panel
   ```
   
   You should see:
   ```
   📍 Local:    http://localhost:3200
   🌐 Network:  http://0.0.0.0:3200
   ```

5. **Test local access first:**
   ```bash
   curl http://localhost:3200
   ```
   
   If this works but external access doesn't, check your firewall settings.

6. **Verify network accessibility:**
   - Ensure your firewall allows incoming connections on port 3200
   - On Linux: `sudo ufw allow 3200/tcp` (if using UFW)
   - On Windows: Check Windows Firewall settings
   - Check your router/network firewall if accessing from different network

**Quick checklist:**
- [ ] Created `.env` file with `HTTP_PORT=3200`
- [ ] Ran `docker-compose down` to remove old container
- [ ] Ran `docker-compose up -d` to create new container with updated port
- [ ] Verified port mapping with `docker ps`
- [ ] Checked container logs for correct port
- [ ] Tested local access with `curl http://localhost:3200`
- [ ] Checked firewall rules for port 3200

## 📸 Features Showcase

### Modern Dark Theme
The admin panel features a sleek, modern dark theme with glassmorphism effects and neon accents, providing a professional and easy-to-use interface.

### Real-Time Updates
All data refreshes automatically every 5 seconds, ensuring you always have the latest information about your server without manual refreshing.

### Comprehensive Control
Every aspect of your ManiaPlanet server can be controlled from a single, unified interface:
- 🎮 Server management
- 👥 Player administration  
- 🗺️ Map pool control
- 💬 Chat interaction
- 📊 Live statistics
- 🏆 Rankings tracking

### Smart Formatting
Automatically handles ManiaPlanet's complex formatting codes, displaying clean, readable text throughout the interface while preserving full compatibility.

### Drag & Drop Upload
Intuitive drag-and-drop interface for map uploads makes adding new content effortless. Simply drag `.gbx` files onto the upload zone or browse to select them.

## License

MIT


## Support 
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/P5P81TXQBY)

<!-- Reference Links -->
[dashboard-screenshot]: https://github.com/user-attachments/assets/44459f92-0f7d-4a98-ad39-57e93b9a0598