# ManiaPlanet Admin Panel

A sleek, modern web-based admin panel for ManiaPlanet game servers (Stadium).

![Dashboard][dashboard-screenshot]

## Tech Stack

- **Backend:** Node.js, Express, `gbxremote` (XML-RPC)
- **Frontend:** Vanilla HTML5, CSS3, ES6 JavaScript

## Features

- 🌑 **Modern UI:** Dark theme with glassmorphism and neon accents
- 📊 **Real-time Dashboard:** Live overview of server status, map info, and players
- 🏎️ **Map Management:** Drag-and-drop map uploads, pool shuffling, and removal
- 👥 **Player Controls:** Kick, Ban, Mute, or Spectate players directly from the UI
- 🕒 **Live Rankings:** Real-time session rankings with accurate best times
- 💬 **Integrated Chat:** Full server chat with ManiaPlanet formatting support
- 🎨 **Clean Display:** Automatically strips ManiaPlanet color codes for readable text
- 🔄 **Server Controls:** Restart server, restart map, skip map, and shuffle map pool
- ⚡ **Expansion Support:** Dedicated restart for ManiaPlanet expansion/controller

## 🐳 Docker

Image: **`ghcr.io/lukasrat/maniaplanet-admin-panel`** — automatically built on every push to `main` and on every version tag.

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `HTTP_PORT` | `3100` | Port the admin panel web server listens on |
| `RPC_HOST` | `dedicated` | Hostname/IP of the ManiaPlanet XML-RPC server |
| `RPC_PORT` | `5000` | XML-RPC port of the ManiaPlanet server |
| `MANIAPLANET_MAPS_DIR` | `/maps` | Path inside the container for map uploads |

### Quick Start with Docker Compose

Both the admin panel and the dedicated server must share the same Docker network (`xmlrpc-network`).

**Option A – Add `adminpanel` to your existing `docker-compose.yml` (recommended):**

```yaml
services:
  adminpanel:
    image: ghcr.io/lukasrat/maniaplanet-admin-panel:latest
    ports:
      - "3100:3100"
    environment:
      - RPC_HOST=dedicated   # must match the service name of your dedicated server
      - RPC_PORT=5000
      - MANIAPLANET_MAPS_DIR=/maps
    volumes:
      - ./Maps:/maps         # point to your server's UserData/Maps directory
    networks:
      - xmlrpc-network
    restart: unless-stopped
```

```bash
docker compose up -d
```

**Option B – Run the standalone `docker-compose.yml` from this repository:**

```bash
# Download the compose file
curl -O https://raw.githubusercontent.com/LukasRat/maniaplanet-admin-panel/main/docker-compose.yml

# Start the admin panel (xmlrpc-network must already exist)
docker compose up -d

# Custom ports (admin panel on 3200, XML-RPC on 5001)
HTTP_PORT=3200 RPC_PORT=5001 docker compose up -d
```

Then open `http://localhost:3100` (or your chosen `HTTP_PORT`) in your browser.

### Quick Start with `docker run`

```bash
docker run -d \
  --network xmlrpc-network \
  -e RPC_HOST=dedicated \
  -v /path/to/maniaplanetserver/UserData/Maps:/maps \
  -p 3100:3100 \
  ghcr.io/lukasrat/maniaplanet-admin-panel:latest
```

> **Note:** Set `RPC_HOST` to the service name of your dedicated server. Replace `/path/to/maniaplanetserver/UserData/Maps` with the actual path on your host.

## Getting Started

### Prerequisites

- Node.js 20+
- A running ManiaPlanet 4 Stadium server with XML-RPC enabled (Port 5000)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/LukasRat/maniaplanet-admin-panel.git
   cd maniaplanet-admin-panel
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set environment variables:

   | Variable | Default | Description |
   |---|---|---|
   | `HTTP_PORT` | `3100` | Port the admin panel listens on |
   | `RPC_HOST` | `127.0.0.1` | Hostname/IP of your ManiaPlanet server |
   | `RPC_PORT` | `5000` | XML-RPC port of your ManiaPlanet server |
   | `MANIAPLANET_MAPS_DIR` | — | Path to your server's `UserData/Maps` directory |

   > **Note:** `MANIAPLANET_MAPS_DIR` must point to your ManiaPlanet server's actual `UserData/Maps` directory for map uploads to work.

4. Start the panel:
   ```bash
   npm start
   ```

5. Open `http://localhost:3100` and log in with your ManiaPlanet server password.

### Configuring Server Restart

The "Restart Server" button requires `restart.sh` to be configured. Open the file, uncomment the method that matches your setup (systemd, screen/tmux, Docker, or custom), then make it executable:

```bash
chmod +x restart.sh
```

### Configuring Expansion Restart (Optional)

Edit `restart_expansion.sh`, set `EXPANSION_DIR` to your expansion's installation path, and make it executable:

```bash
chmod +x restart_expansion.sh
```

## Troubleshooting

- **Map uploads fail** – Set `MANIAPLANET_MAPS_DIR` to your server's `UserData/Maps` directory and ensure the admin panel has write access.
- **Cannot find module 'express'** – Run `npm install` first.
- **Server won't connect** – Ensure XML-RPC is enabled on your ManiaPlanet server (port 5000).
- **Port already in use** – Change `HTTP_PORT` (e.g. `HTTP_PORT=3200 npm start`).

## License

MIT


## Support 
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/P5P81TXQBY)

<!-- Reference Links -->
[dashboard-screenshot]: https://github.com/user-attachments/assets/44459f92-0f7d-4a98-ad39-57e93b9a0598
