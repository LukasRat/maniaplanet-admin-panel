#!/usr/bin/env node
// Simple dependency check before starting the server
const fs = require('fs');

if (!fs.existsSync('node_modules')) {
  console.error('\n❌ Error: Dependencies not installed!\n\nPlease run: npm install\n');
  process.exit(1);
}
