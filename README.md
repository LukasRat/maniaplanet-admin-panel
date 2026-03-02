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

## Screenshots

| Login | Dashboard |
|-------|-----------|
| ![Login][login-screenshot] | ![Dashboard][dashboard-screenshot] |

| Players | Chat |
|---------|------|
| ![Players][players-screenshot] | ![Chat][chat-screenshot] |

| Map Pool | Map Upload |
|----------|------------|
| ![Map Pool][mappool-screenshot] | ![Map Upload][mapupload-screenshot] |

| Server Controls |
|-----------------|
| ![Server Controls][server-screenshot] |

## 🐳 Docker

Image: **`ghcr.io/lukasrat/maniaplanet-admin-panel`** — automatically built on every push to `main` and on every version tag.

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `HTTP_PORT` | `3100` | Port the admin panel web server listens on |
| `RPC_HOST` | `dedicated` | Hostname/IP of the ManiaPlanet XML-RPC server |
| `RPC_PORT` | `5000` | XML-RPC port of the ManiaPlanet server |
| `MANIAPLANET_MAPS_DIR` | `/maps` | Path inside the container for map uploads |
| `DEDICATED_CONTAINER` | `dedicated` | Docker container name of the dedicated game server |
| `EXPANSION_CONTAINER` | `expansion` | Docker container name of the expansion/controller |
| `DOCKER_SOCKET` | `/var/run/docker.sock` | Path to the Docker socket inside the container |

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
      - DEDICATED_CONTAINER=dedicated   # container name for "Restart Server" button
      - EXPANSION_CONTAINER=expansion   # container name for "Restart Expansion" button
    volumes:
      - ./Maps:/maps         # point to your server's UserData/Maps directory
      - /var/run/docker.sock:/var/run/docker.sock  # required for container restart buttons
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
   | `DEDICATED_CONTAINER` | `dedicated` | Docker container name for "Restart Server" |
   | `EXPANSION_CONTAINER` | `expansion` | Docker container name for "Restart Expansion" |

   > **Note:** `MANIAPLANET_MAPS_DIR` must point to your ManiaPlanet server's actual `UserData/Maps` directory for map uploads to work.

4. Start the panel:
   ```bash
   npm start
   ```

5. Open `http://localhost:3100` and log in with your ManiaPlanet server password.

### Configuring Container Restart (Docker)

The "Restart Server" and "Restart Expansion" buttons use the Docker API to restart the corresponding containers. To enable them:

1. Mount the Docker socket into the admin panel container:
   ```yaml
   volumes:
     - /var/run/docker.sock:/var/run/docker.sock
   ```

2. Set the container name environment variables to match your deployment:
   ```yaml
   environment:
     - DEDICATED_CONTAINER=dedicated_masterlol   # your dedicated server container name
     - EXPANSION_CONTAINER=expansion_masterlol   # your expansion container name
   ```

> **Note:** The default values (`dedicated` / `expansion`) match the service names in a standard compose setup. Use `docker ps` to find the exact container names in your deployment.

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
[dashboard-screenshot]: docs/adminpanel_dashboard.png
[login-screenshot]: docs/adminpanel_loginpng.png
[players-screenshot]: docs/adminpanel_players.png
[chat-screenshot]: docs/adminpanel_chatpng.png
[mappool-screenshot]: docs/adminpanel_mappool.png
[mapupload-screenshot]: docs/adminpanel_mapupload.png
[server-screenshot]: docs/adminpanel_server.png
