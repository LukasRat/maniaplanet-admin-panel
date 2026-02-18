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

# Expose the application port
EXPOSE 3100

# Set environment variable for maps directory (can be overridden)
ENV MANIAPLANET_MAPS_DIR=/maps

# Health check to verify the application is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3100', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Run the application
CMD ["npm", "start"]
