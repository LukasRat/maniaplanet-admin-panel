FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

# Default HTTP port for the admin panel web interface
ENV HTTP_PORT=3100
# Host and port of the ManiaPlanet server's XML-RPC interface
ENV RPC_HOST=host.docker.internal
ENV RPC_PORT=5000
# Path inside the container where ManiaPlanet Maps are stored (mount a volume here)
ENV MANIAPLANET_MAPS_DIR=/maps

RUN mkdir -p /maps

# EXPOSE uses the default port; override at runtime with -e HTTP_PORT=<port> and -p <port>:<port>
EXPOSE 3100

CMD ["node", "server.js"]
