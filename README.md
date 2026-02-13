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
   Open `http://localhost:3100` in your browser and enter your ManiaPlanet server password to login.

## Running as a Background Service/Daemon

The admin panel can be run as a background daemon that starts automatically on system boot and doesn't depend on a user shell. Choose one of the following methods based on your setup:

### Method 1: systemd Service (Recommended for Linux)

systemd is the standard init system for most modern Linux distributions. This method ensures the admin panel starts automatically on boot and restarts on failure.

#### Quick Installation (Automated)

Run the automated installation script:

```bash
chmod +x install-systemd.sh
./install-systemd.sh
```

The script will:
- Create a dedicated system user
- Copy files to `/opt/maniaplanet-admin-panel`
- Install npm dependencies
- Create and configure the systemd service
- Start the service and enable auto-start on boot

#### Manual Setup Instructions

1. **Create a dedicated user** (optional but recommended for security):
   ```bash
   sudo useradd -r -s /bin/false maniaplanet
   ```

2. **Install the application** to a system directory:
   ```bash
   sudo mkdir -p /opt/maniaplanet-admin-panel
   sudo cp -r /path/to/your/maniaplanet-admin-panel/* /opt/maniaplanet-admin-panel/
   sudo chown -R maniaplanet:maniaplanet /opt/maniaplanet-admin-panel
   ```

3. **Configure the service file** (`maniaplanet-admin-panel.service`):
   - Edit the `WorkingDirectory` path if you installed to a different location
   - Set the `User` and `Group` to match your setup
   - Uncomment and set `MANIAPLANET_MAPS_DIR` environment variable
   - Add `ReadWritePaths` for your maps directory if needed

4. **Install the systemd service**:
   ```bash
   sudo cp maniaplanet-admin-panel.service /etc/systemd/system/
   sudo systemctl daemon-reload
   ```

5. **Start and enable the service**:
   ```bash
   # Start the service
   sudo systemctl start maniaplanet-admin-panel
   
   # Enable auto-start on boot
   sudo systemctl enable maniaplanet-admin-panel
   
   # Check status
   sudo systemctl status maniaplanet-admin-panel
   ```

#### Managing the Service

```bash
# View logs
sudo journalctl -u maniaplanet-admin-panel -f

# Restart the service
sudo systemctl restart maniaplanet-admin-panel

# Stop the service
sudo systemctl stop maniaplanet-admin-panel

# Disable auto-start
sudo systemctl disable maniaplanet-admin-panel
```

### Method 2: PM2 Process Manager (Cross-Platform)

PM2 is a popular Node.js process manager that works on Linux, Windows, and macOS. It provides automatic restarts, log management, and easy monitoring.

#### Setup Instructions

1. **Install PM2 globally**:
   ```bash
   npm install -g pm2
   ```

2. **Configure the ecosystem file** (`ecosystem.config.js`):
   - Uncomment and set `MANIAPLANET_MAPS_DIR` in the env section
   - Adjust log file paths if needed

3. **Start the application with PM2**:
   ```bash
   # Start using the ecosystem config
   pm2 start ecosystem.config.js
   
   # Save the PM2 process list
   pm2 save
   
   # Set up PM2 to start on system boot
   pm2 startup
   # Follow the instructions displayed by the command above
   ```

#### Managing with PM2

```bash
# View application status
pm2 status

# View logs
pm2 logs maniaplanet-admin-panel

# Restart the application
pm2 restart maniaplanet-admin-panel

# Stop the application
pm2 stop maniaplanet-admin-panel

# Remove from PM2
pm2 delete maniaplanet-admin-panel

# Monitor all PM2 processes
pm2 monit
```

### Method 3: Docker / Docker Compose (Containerized)

Docker provides complete isolation and easy deployment. This method is ideal for container-based environments.

#### Setup Instructions

1. **Edit `docker-compose.yml`**:
   - Update the volumes section to point to your actual ManiaPlanet server's Maps directory
   - Set the `MANIAPLANET_MAPS_DIR` environment variable
   - Adjust the port mapping if needed (default: 3100:3100)

2. **Build and start the container**:
   ```bash
   # Build and start in detached mode
   docker-compose up -d
   
   # View logs
   docker-compose logs -f
   
   # Check status
   docker-compose ps
   ```

3. **The container will**:
   - Start automatically on system boot (restart: unless-stopped)
   - Restart automatically on failure
   - Persist logs to the ./logs directory
   - Access your ManiaPlanet server's Maps directory

#### Managing the Docker Container

```bash
# Stop the container
docker-compose down

# Restart the container
docker-compose restart

# View logs
docker-compose logs -f maniaplanet-admin-panel

# Rebuild after code changes
docker-compose up -d --build

# Execute commands inside the container
docker-compose exec maniaplanet-admin-panel sh
```

### Method 4: nohup (Simple Background Process)

For quick setup without installing additional tools:

```bash
# Start in background
nohup npm start > adminpanel.log 2>&1 &

# Get the process ID
echo $!

# View logs
tail -f adminpanel.log

# Stop (replace PID with actual process ID)
kill <PID>
```

**Note:** This method doesn't provide automatic restart or boot startup. Consider using systemd or PM2 for production deployments.

### Choosing the Right Method

| Method | Best For | Auto-Restart | Auto-Start on Boot | Log Management | Cross-Platform |
|--------|----------|--------------|-------------------|----------------|----------------|
| systemd | Linux servers | ✅ | ✅ | ✅ (journalctl) | ❌ Linux only |
| PM2 | Node.js apps | ✅ | ✅ | ✅ (built-in) | ✅ Yes |
| Docker | Containerized environments | ✅ | ✅ | ✅ (docker logs) | ✅ Yes |
| nohup | Quick testing | ❌ | ❌ | ⚠️ Manual | ✅ Yes |

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

- **Server won't connect:** Ensure your ManiaPlanet server is running with XML-RPC enabled on port 5000
- **Port 3100 already in use:** Change `HTTP_PORT` in `server.js` or stop the process using port 3100

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