/**
 * Maniaplanet 4 Stadium – Admin Panel Server
 * Node.js 20+
 */

const express = require('express')
const cors = require('cors')
const path = require('path')
const fs = require('fs')
const fsPromises = require('fs').promises
const multer = require('multer')
const gbxremote = require('gbxremote')
const { exec } = require('child_process')
const util = require('util')
const execPromise = util.promisify(exec)

// Handle unhandled promise rejections to prevent server crashes
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection:', reason)
})

/* =========================
   CONFIG
========================= */

const HTTP_HOST = '0.0.0.0'  // Listen on all network interfaces
const HTTP_PORT = 3100

const RPC_HOST = '127.0.0.1'
const RPC_PORT = 5000
const RPC_LOGIN = 'SuperAdmin'

// MAPS_DIR must point to your Maniaplanet server's UserData/Maps directory
// This is REQUIRED for map uploads to work!
// 
// Examples:
//   Linux: '/home/user/Desktop/maniaplanetserver/UserData/Maps'
//   Windows: 'C:\\ManiaPlanetServer\\UserData\\Maps'
//   Docker: '/server/UserData/Maps'
// 
// IMPORTANT: 
// - This must be the ACTUAL path where your Maniaplanet server's Maps directory is located
// - The admin panel must have write permissions to this directory
// - Map files will be saved directly to this directory
const MAPS_DIR = process.env.MANIAPLANET_MAPS_DIR || '/home/user/Desktop/maniaplanetserver/UserData/Maps'

// Ensure maps directory exists
if (!fs.existsSync(MAPS_DIR)) {
  fs.mkdirSync(MAPS_DIR, { recursive: true })
}

/* =========================
   EXPRESS
========================= */

const app = express()
app.use(cors())
app.use(express.json())

app.use(express.static(path.join(__dirname, 'public')))
app.get('/', (_, res) =>
  res.sendFile(path.join(__dirname, 'public', 'panel.html'))
)

/* =========================
   GBXREMOTE
========================= */

let rpc = null
let rpcReady = false
let rpcConnecting = false
let rpcPassword = null

function createRpcClient() {
  if (!rpc) {
    rpc = gbxremote.createClient({
      host: RPC_HOST,
      port: RPC_PORT
    })
    
    // Prevent server crashes from RPC connection errors
    rpc.on('error', (err) => {
      console.error('RPC connection error:', err.message)
      rpcReady = false
    })
  }
  return rpc
}

async function connectRpc() {
  if (rpcReady) return
  if (rpcConnecting) {
    while (!rpcReady) await new Promise(r => setTimeout(r, 50))
    return
  }

  if (!rpcPassword) {
    throw new Error('Password required for RPC connection')
  }

  rpcConnecting = true
  try {
    const client = createRpcClient()
    await client.connect()
    await client.query('Authenticate', [RPC_LOGIN, rpcPassword])
    rpcReady = true
  } catch (err) {
    console.error('RPC Connection failed:', err.message)
    rpcReady = false
    // Only clear password on authentication errors, not connection errors
    if (err.message && err.message.includes('Auth')) {
      rpcPassword = null
    }
    throw err
  }
  rpcConnecting = false
}

async function rpcCall(method, params = []) {
  await connectRpc()
  if (!rpcReady) throw new Error('Not connected to Maniaplanet Server')
  return createRpcClient().query(method, params)
}

/* =========================
   HELPERS
========================= */

function validateFilename(filename) {
  // Validate the extension
  if (!/\.(?:Map\.)?Gbx$/i.test(filename)) {
    throw new Error('Invalid map file extension. File must end with .gbx or .Map.Gbx')
  }
  
  // Use basename to strip any path components (security: prevent directory traversal)
  const basename = path.basename(filename)
  
  // Check for dangerous patterns (path traversal attempts)
  if (basename.includes('..') || basename !== filename) {
    throw new Error('Invalid filename: path traversal detected')
  }
  
  // Ensure filename is not empty or just dots
  if (!basename || /^\.+$/.test(basename)) {
    throw new Error('Invalid filename')
  }
  
  // Return the original filename (Maniaplanet needs exact filename)
  return basename
}

async function ensureMapInPool(file) {
  const maps = await rpcCall('GetChallengeList', [1000, 0])
  const exists = maps.some(m => m.FileName === file)
  if (!exists) await rpcCall('AddMap', [file])
}

function getGameModeName(gameModeNumber) {
  const gameModeNames = {
    0: 'Script',
    1: 'Rounds',
    2: 'TimeAttack',
    3: 'Team',
    4: 'Laps',
    5: 'Cup',
    6: 'Stunts'
  }
  return gameModeNames[gameModeNumber] || `Mode ${gameModeNumber}`
}

/* =========================
   MULTER
========================= */
const upload = multer({
  dest: MAPS_DIR,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit for map files
  }
})


/* =========================
   API
========================= */

app.post('/api/login', async (req, res) => {
  try {
    const { password } = req.body
    
    if (!password) {
      return res.status(400).json({ error: 'Password is required' })
    }

    // Set the password for RPC connection
    rpcPassword = password
    
    // Reset connection state to force re-authentication
    rpcReady = false
    
    await connectRpc()
    if (rpcReady) {
      res.json({ ok: true })
    } else {
      rpcPassword = null
      res.status(503).json({ error: 'Could not connect to Game Server' })
    }
  } catch (err) {
    console.error('Login error:', err.message)
    // Only clear password on auth failures
    if (err.message && err.message.includes('Auth')) {
      rpcPassword = null
      res.status(401).json({ error: 'Authentication failed. Check your password.' })
    } else {
      res.status(503).json({ error: 'Could not connect to Game Server. Check if server is running.' })
    }
  }
})

app.get('/api/status', async (_, res) => {
  try {
    const [players, maps, currentMap, banList, gameMode] = await Promise.all([
      rpcCall('GetPlayerList', [100, 0]),
      rpcCall('GetChallengeList', [1000, 0]),
      rpcCall('GetCurrentChallengeInfo'),
      rpcCall('GetBanList', [1000, 0]).catch(() => []),
      rpcCall('GetGameMode').catch(() => null)
    ])

    res.json({ 
      players, 
      maps, 
      currentMap, 
      banCount: banList.length,
      gameMode: gameMode !== null ? getGameModeName(gameMode) : 'Unknown'
    })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

/* =========================
   MAP FILES (NEU)
========================= */

app.get('/api/maps/files', (_, res) => {
  try {
    if (!fs.existsSync(MAPS_DIR)) {
      fs.mkdirSync(MAPS_DIR, { recursive: true })
    }
    const files = fs.readdirSync(MAPS_DIR)
      .filter(f => /\.(map\.)?gbx$/i.test(f))
      .sort()

    res.json(files)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

/* =========================
   MAP ACTIONS
========================= */

app.post('/api/maps/next', async (req, res) => {
  try {
    const file = req.body.file
    await ensureMapInPool(file)
    await rpcCall('ChooseNextMap', [file])
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/maps/upload', upload.array('map'), async (req, res) => {
  try {
    if (!req.files || !req.files.length) {
      return res.status(400).json({ error: 'Keine Dateien empfangen' })
    }

    const added = []
    const skipped = []
    const errors = []

    for (const file of req.files) {
      try {
        // Validate filename for security (but don't modify it)
        // Maniaplanet needs the exact original filename
        const validatedName = validateFilename(file.originalname)
        
        const tempPath = file.path
        const finalPath = path.join(MAPS_DIR, validatedName)

        // Move file directly to the server's Maps directory
        fs.renameSync(tempPath, finalPath)

        // Small pause to let Maniaplanet detect the new file
        await new Promise(r => setTimeout(r, 300))

        // Check if map already exists in playlist before adding
        const maps = await rpcCall('GetChallengeList', [1000, 0])
        const exists = maps.some(m => m.FileName === validatedName)
        
        if (exists) {
          // Map already in playlist, but file was uploaded successfully
          skipped.push(validatedName)
          console.log(`Map ${validatedName} already in playlist, skipped AddMap`)
        } else {
          // Register map with Maniaplanet server
          await rpcCall('AddMap', [validatedName])
          added.push(validatedName)
        }
      } catch (e) {
        console.error(`Could not add map ${file.originalname} to server:`, e.message)
        errors.push({ file: file.originalname, error: e.message })
      }
    }

    res.json({
      ok: true,
      maps: added,
      skipped: skipped,
      errors: errors
    })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

/* =========================
   SERVER MANAGEMENT
========================= */

app.get('/api/server/info', async (_, res) => {
  try {
    const [version, status, serverName, maxPlayers, maxSpectators, networkStats] = await Promise.all([
      rpcCall('GetVersion'),
      rpcCall('GetStatus'),
      rpcCall('GetServerName'),
      rpcCall('GetMaxPlayers'),
      rpcCall('GetMaxSpectators'),
      rpcCall('GetNetworkStats').catch(() => null)
    ])

    res.json({
      version,
      status,
      serverName,
      maxPlayers: maxPlayers.CurrentValue,
      maxSpectators: maxSpectators.CurrentValue,
      networkStats: networkStats || {}
    })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/server/settings', async (req, res) => {
  try {
    const { serverName, maxPlayers, maxSpectators, password } = req.body

    if (serverName) await rpcCall('SetServerName', [serverName])
    if (maxPlayers) await rpcCall('SetMaxPlayers', [maxPlayers])
    if (maxSpectators) await rpcCall('SetMaxSpectators', [maxSpectators])
    if (password !== undefined) await rpcCall('SetServerPassword', [password])

    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/server/skip-map', async (_, res) => {
  try {
    await rpcCall('NextMap')
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/server/restart-map', async (_, res) => {
  try {
    await rpcCall('RestartMap')
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/server/restart', async (_, res) => {
  try {
    // Execute the restart.sh script
    const scriptPath = path.join(__dirname, 'restart.sh')
    
    // Check if restart.sh exists
    if (!fs.existsSync(scriptPath)) {
      return res.status(500).json({ 
        error: 'restart.sh script not found. Please create and configure the restart script.' 
      })
    }
    
    // Check if the script is executable
    try {
      fs.accessSync(scriptPath, fs.constants.X_OK)
    } catch (err) {
      return res.status(500).json({
        error: 'restart.sh script is not executable. Run: chmod +x restart.sh'
      })
    }
    
    // Execute the script and capture output
    try {
      const { stdout, stderr } = await execPromise(scriptPath)
      
      // Log the output
      console.log('=== Restart Script Success ===')
      console.log(stdout)
      if (stderr) console.log('stderr:', stderr)
      console.log('==============================')
      
      res.json({ 
        ok: true, 
        message: 'Server restart completed successfully.',
        output: stdout
      })
    } catch (error) {
      // Script failed - this is expected if not configured
      const output = error.stdout || error.stderr || error.message
      
      console.log('=== Restart Script Failed ===')
      console.log('Exit code:', error.code)
      console.log('Output:', output)
      console.log('=============================')
      
      // Return error with the script's output so user knows what to configure
      return res.status(500).json({ 
        error: 'Restart script not configured or failed. Please configure restart.sh for your server setup.',
        details: output,
        exitCode: error.code
      })
    }
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/server/restart-expansion', async (_, res) => {
  try {
    // Execute the restart_expansion.sh script
    const scriptPath = path.join(__dirname, 'restart_expansion.sh')
    
    // Check if restart_expansion.sh exists
    if (!fs.existsSync(scriptPath)) {
      return res.status(500).json({ 
        error: 'restart_expansion.sh script not found. Please create the expansion restart script.' 
      })
    }
    
    // Check if the script is executable
    try {
      fs.accessSync(scriptPath, fs.constants.X_OK)
    } catch (err) {
      return res.status(500).json({
        error: 'restart_expansion.sh script is not executable. Run: chmod +x restart_expansion.sh'
      })
    }
    
    // Execute the script and capture output
    try {
      const { stdout, stderr } = await execPromise(scriptPath)
      
      // Log the output
      console.log('=== Expansion Restart Script Success ===')
      console.log(stdout)
      if (stderr) console.log('stderr:', stderr)
      console.log('=========================================')
      
      res.json({ 
        ok: true, 
        message: 'Expansion restart completed successfully.',
        output: stdout
      })
    } catch (error) {
      // Script failed
      const output = error.stdout || error.stderr || error.message
      
      console.log('=== Expansion Restart Script Failed ===')
      console.log('Exit code:', error.code)
      console.log('Output:', output)
      console.log('========================================')
      
      // Return error with the script's output
      return res.status(500).json({ 
        error: 'Expansion restart script failed. Check server logs for details.',
        details: output,
        exitCode: error.code
      })
    }
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

/* =========================
   ENHANCED PLAYER MANAGEMENT
========================= */

app.post('/api/players/spectate', async (req, res) => {
  try {
    const { login } = req.body
    await rpcCall('ForceSpectator', [login, 1]) // 1 = force to spectator
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/players/force-team', async (req, res) => {
  try {
    const { login, team } = req.body // team: 0 = blue, 1 = red
    await rpcCall('ForcePlayerTeam', [login, team])
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/players/kick', async (req, res) => {
  try {
    const { login } = req.body
    await rpcCall('Kick', [login])
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/players/ban', async (req, res) => {
  try {
    const { login } = req.body
    await rpcCall('Ban', [login])
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.get('/api/players/detailed', async (_, res) => {
  try {
    const players = await rpcCall('GetPlayerList', [100, 0])
    const detailed = await Promise.all(
      players.map(async (p) => {
        try {
          const info = await rpcCall('GetDetailedPlayerInfo', [p.Login])
          return { ...p, ...info }
        } catch {
          return p
        }
      })
    )
    res.json(detailed)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

/* =========================
   ADVANCED MAP MANAGEMENT
========================= */

app.post('/api/maps/remove', async (req, res) => {
  try {
    const { file } = req.body
    await rpcCall('RemoveMap', [file])
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/maps/shuffle', async (_, res) => {
  try {
    const maps = await rpcCall('GetChallengeList', [1000, 0])
    const shuffled = maps.map(m => m.FileName).sort(() => Math.random() - 0.5)

    // Remove all maps and re-add in shuffled order
    for (const map of maps) {
      await rpcCall('RemoveMap', [map.FileName])
    }
    for (const fileName of shuffled) {
      await rpcCall('AddMap', [fileName])
    }

    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/maps/insert', async (req, res) => {
  try {
    const { file, position } = req.body
    await rpcCall('InsertMap', [file, position])
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

/* =========================
   LIVE GAME INFO
========================= */

app.get('/api/game/rankings', async (req, res) => {
  try {
    const { map } = req.query

    // Get current map info if no specific map requested
    const currentMap = map || (await rpcCall('GetCurrentChallengeInfo')).FileName

    // Get rankings for the current/specified map
    const rankings = await rpcCall('GetCurrentRanking', [100, 0])

    // Enrich each ranking with BestTime by fetching individual player records
    const enrichedRankings = await Promise.all(
      rankings.map(async (player) => {
        try {
          // GetCurrentRankingForLogin returns array with player's ranking including BestTime
          const playerRanking = await rpcCall('GetCurrentRankingForLogin', [player.Login])
          return {
            ...player,
            BestTime: playerRanking && playerRanking.length > 0 ? playerRanking[0].BestTime : -1
          }
        } catch (e) {
          return { ...player, BestTime: -1 }
        }
      })
    )

    // Filter out players with no time and sort by best time
    const validRankings = enrichedRankings
      .filter(p => p.BestTime > 0)
      .sort((a, b) => a.BestTime - b.BestTime)

    res.json(validRankings)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.get('/api/game/status', async (_, res) => {
  try {
    const gameStatus = await rpcCall('GetStatus')
    res.json(gameStatus)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

/* =========================
   CHAT & COMMUNICATION
========================= */

app.post('/api/chat/send', async (req, res) => {
  try {
    const { message } = req.body
    await rpcCall('ChatSendServerMessage', [message])
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/chat/private', async (req, res) => {
  try {
    const { login, message } = req.body
    await rpcCall('ChatSendServerMessageToLogin', [message, login])
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.get('/api/chat/lines', async (_, res) => {
  try {
    const chatLines = await rpcCall('GetChatLines')
    res.json(chatLines)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

/* =========================
   GAME MODE & MODE SCRIPT INFO
========================= */

app.get('/api/game/mode', async (_, res) => {
  try {
    const [gameMode, modeScriptInfo] = await Promise.all([
      rpcCall('GetGameMode').catch(() => null),
      rpcCall('GetModeScriptInfo').catch(() => null)
    ])
    
    res.json({
      gameMode: gameMode,
      gameModeName: gameMode !== null ? getGameModeName(gameMode) : 'Unknown',
      modeScriptInfo: modeScriptInfo || {}
    })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

/* =========================
   NETWORK STATISTICS
========================= */

app.get('/api/network/stats', async (_, res) => {
  try {
    const networkStats = await rpcCall('GetNetworkStats').catch(() => null)
    res.json(networkStats || {})
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

/* =========================
   VOTE SYSTEM
========================= */

app.get('/api/votes/status', async (_, res) => {
  try {
    const callVoteRatio = await rpcCall('GetCallVoteRatio').catch(() => null)
    
    // Return empty object if vote ratio unavailable for consistency
    if (callVoteRatio === null) {
      return res.json({})
    }
    
    res.json({
      callVoteRatio: callVoteRatio
    })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

/* =========================
   MAP INFORMATION
========================= */

app.get('/api/maps/info/:filename', async (req, res) => {
  try {
    const { filename } = req.params
    const mapInfo = await rpcCall('GetMapInfo', [filename])
    res.json(mapInfo)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

/* =========================
   BAN MANAGEMENT
========================= */

app.get('/api/bans/list', async (req, res) => {
  try {
    const banList = await rpcCall('GetBanList', [1000, 0])
    res.json(banList)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/bans/unban', async (req, res) => {
  try {
    const { login } = req.body
    await rpcCall('UnBan', [login])
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/bans/clear', async (req, res) => {
  try {
    await rpcCall('CleanBanList')
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

/* =========================
   START
========================= */

app.listen(HTTP_PORT, HTTP_HOST, () => {
  console.log('\n🚀 Maniaplanet Admin Panel Server Started!')
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  console.log(`📍 Local:    http://localhost:${HTTP_PORT}`)
  console.log(`🌐 Network:  http://${HTTP_HOST}:${HTTP_PORT}`)
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  console.log('👉 Open http://localhost:3100 in your browser')
  console.log('🔐 Enter your maniaplanet Superadmin password to login\n')
})
