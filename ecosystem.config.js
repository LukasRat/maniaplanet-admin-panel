/**
 * PM2 Ecosystem Configuration for ManiaPlanet Admin Panel
 * 
 * This file configures PM2 to run the admin panel as a background daemon.
 * PM2 provides automatic restarts, log management, and process monitoring.
 * 
 * Usage:
 *   pm2 start ecosystem.config.js
 *   pm2 save
 *   pm2 startup
 */

module.exports = {
  apps: [{
    name: 'maniaplanet-admin-panel',
    script: './server.js',
    instances: 1,
    exec_mode: 'fork',
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      // Uncomment and set your maps directory path
      // MANIAPLANET_MAPS_DIR: '/path/to/maniaplanetserver/UserData/Maps'
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_file: './logs/pm2-combined.log',
    time: true,
    merge_logs: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
}
