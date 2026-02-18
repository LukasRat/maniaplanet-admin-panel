# Use Node.js 20 LTS as base image
FROM node:20-slim

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json ./

# Install dependencies (npm install is more reliable than npm ci on alpine sometimes)
# Using --prefer-offline and --no-audit for faster, more stable installs
RUN npm install --prefer-offline --no-audit

# Copy application files
COPY . .

# Create directory for map storage (can be overridden with volume mount)
RUN mkdir -p /maps

# Expose the application port (default 3100, configurable via HTTP_PORT)
EXPOSE 3100

# Set environment variables with defaults
ENV MANIAPLANET_MAPS_DIR=/maps \
    HTTP_PORT=3100 \
    HTTP_HOST=0.0.0.0 \
    RPC_HOST=127.0.0.1 \
    RPC_PORT=5000 \
    RPC_LOGIN=SuperAdmin

# Health check to verify the application is running
# Uses HTTP_PORT environment variable
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "const port = process.env.HTTP_PORT || 3100; require('http').get('http://localhost:' + port, (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Run the application
CMD ["npm", "start"]
