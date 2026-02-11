# ManiaPlanet Admin Panel Modernized

A sleek, modern, and powerful web-based admin panel for ManiaPlanet game servers (Stadium).

![Dashboard](public/screenshot.png)

## Features

- 🌑 **Modern UI:** Dark theme with glassmorphism and neon accents.
- 📊 **Real-time Dashboard:** Live overview of server status, map info, and players.
- 🏎️ **Map Management:** Drag-and-drop map uploads, pool shuffling, and removal.
- 👥 **Player Controls:** Kick, Ban, Mute, or Spectate players directly from the UI.
- 🕒 **Live Rankings:** Real-time session rankings with accurate best times.
- 💬 **Integrated Chat:** Full server chat integration with support for ManiaPlanet color codes.
- 🔄 **Server Restart:** Restart the game server via configurable restart.sh script.

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

3. Configure your server:
   Edit `server.js` and update the constants at the top:
   ```javascript
   const RPC_HOST = '127.0.0.1';
   const RPC_PORT = 5000;
   const RPC_LOGIN = 'SuperAdmin';
   ```

4. Start the panel:
   ```bash
   npm start
   ```

5. Access the panel:
   Open `http://localhost:3100` in your browser and enter your ManiaPlanet server password to login.

### Server Restart Feature

The admin panel includes a server restart feature using the `restart.sh` script.

#### How It Works

When you click "Restart Server":
1. The restart script runs as a detached background process
2. The script stops the admin panel, ManiaPlanet server, and expansion
3. It restarts everything in the correct order
4. The admin panel comes back online automatically

#### Configuration

The `restart.sh` script is pre-configured for the following setup:
- Server directory: `/home/user/Desktop/maniaplanetserver`
- Expansion directory: `/home/user/Desktop/expansion`
- Admin panel directory: `/home/user/Desktop/maniaplanetserver/adminpanel`
- IP file: `/home/user/Desktop/maniaplanetserver/last_public_ip.txt`

**If your paths are different**, edit the configuration section at the top of `restart.sh`.

#### Monitoring Restarts

The restart script logs all output to `restart_server.log` in the admin panel directory. You can monitor the restart progress:

```bash
tail -f /home/user/Desktop/maniaplanetserver/adminpanel/restart_server.log
```

#### Troubleshooting

- **Script doesn't run** - Check that `restart.sh` is executable: `chmod +x restart.sh`
- **IP file error** - Ensure `/home/user/Desktop/maniaplanetserver/last_public_ip.txt` exists and contains a valid IP
- **Script fails** - Check `restart_server.log` for detailed error messages
- **Server doesn't restart** - Verify the paths in the configuration section match your setup

## Troubleshooting

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

## License

MIT


## Support 
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/P5P81TXQBY)