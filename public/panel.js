const API = `${window.location.origin}/api`  // Use current host instead of hardcoded localhost

// Application State & Logic
const app = {
  state: {
    currentTab: 'dashboard',
    lastPlayers: [],
    autoRefresh: null
  },

  // --- Core Functions ---

  async login() {
    try {
      const password = document.getElementById('loginPassword').value.trim()
      if (!password) {
        this.showToast('Please enter a password', 'error')
        return
      }

      const res = await fetch(`${API}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ password })
      })
      
      if (!res.ok) {
        const error = await res.json().catch(() => ({ error: 'Login failed' }))
        throw new Error(error.error || 'Login failed')
      }

      this.showToast('Connected to Server', 'success')

      document.getElementById('loginBox').classList.add('hidden')
      document.getElementById('app-container').classList.add('visible')

      await this.refresh()
      this.state.autoRefresh = setInterval(() => this.refresh(), 5000)

      // Init Drag & Drop
      this.initDragAndDrop()

    } catch (e) {
      this.showToast(e.message || 'Login failed. Check server.', 'error')
    }
  },

  logout() {
    // Clear auto refresh interval
    if (this.state.autoRefresh) {
      clearInterval(this.state.autoRefresh)
      this.state.autoRefresh = null
    }

    // Reset state
    this.state.currentTab = 'dashboard'
    this.state.lastPlayers = []

    // Clear password input
    document.getElementById('loginPassword').value = ''

    // Hide app container and show login box
    document.getElementById('app-container').classList.remove('visible')
    document.getElementById('loginBox').classList.remove('hidden')

    // Reset active tab
    document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'))
    document.querySelectorAll('.nav-item')[0].classList.add('active')

    // Hide all sections
    document.querySelectorAll('.section').forEach(el => el.classList.remove('active'))
    document.getElementById('tab-dashboard').classList.add('active')

    this.showToast('Logged out successfully', 'success')
  },

  async refresh() {
    try {
      const [statusRes, filesRes, serverInfoRes, rankingsRes, chatRes] = await Promise.all([
        fetch(`${API}/status`),
        fetch(`${API}/maps/files`),
        fetch(`${API}/server/info`).catch(() => null),
        fetch(`${API}/game/rankings`).catch(() => null),
        fetch(`${API}/chat/lines`).catch(() => null)
      ])

      const status = await statusRes.json()
      const files = await filesRes.json()

      this.renderDashboard(status)
      this.renderPlayers(status.players)
      this.renderMaps(files, status.maps, status.currentMap)

      // Render server info if available
      if (serverInfoRes && serverInfoRes.ok) {
        const serverInfo = await serverInfoRes.json()
        this.renderServerInfo(serverInfo)
      }

      // Render rankings if available
      if (rankingsRes && rankingsRes.ok) {
        const rankings = await rankingsRes.json()
        this.renderRankings(rankings)
      }

      // Render chat if available
      if (chatRes && chatRes.ok) {
        const chatLines = await chatRes.json()
        this.renderChat(chatLines)
      }

    } catch (e) {
      console.error('Refresh failed', e)
    }
  },

  // --- UI Actions ---

  switchTab(tabId) {
    this.state.currentTab = tabId

    // Update Nav
    document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'))
    event.currentTarget.classList.add('active')

    // Update Content
    document.querySelectorAll('.section').forEach(el => el.classList.remove('active'))
    document.getElementById(`tab-${tabId}`).classList.add('active')
  },

  showToast(msg, type = 'success') {
    const toast = document.getElementById('status-toast')
    const icon = toast.querySelector('i')
    const text = document.getElementById('toast-message')

    text.textContent = msg

    // Reset classes
    icon.className = ''
    toast.style.borderColor = type === 'success' ? 'var(--success)' : 'var(--danger)'

    if (type === 'success') {
      icon.classList.add('fa-solid', 'fa-circle-check')
      icon.style.color = 'var(--success)'
    } else {
      icon.classList.add('fa-solid', 'fa-circle-exclamation')
      icon.style.color = 'var(--danger)'
    }

    toast.classList.add('show')
    setTimeout(() => toast.classList.remove('show'), 3000)
  },

  // --- Renderers ---

  renderDashboard(status) {
    document.getElementById('stat-players').textContent = status.players.length
    document.getElementById('stat-maps').textContent = status.maps.length

    if (status.currentMap) {
      const cleanName = status.currentMap.Name.replace(/\$[0-9a-fA-F]{1,3}/g, '') // Strip color codes roughly
      document.getElementById('stat-current').textContent = cleanName
      document.getElementById('stat-current').title = cleanName
    }
  },

  renderPlayers(players) {
    const list = document.getElementById('players-list')
    list.innerHTML = ''

    if (players.length === 0) {
      list.innerHTML = '<div style="padding: 20px; color: var(--text-muted); text-align: center;">No players online</div>'
      return
    }

    const now = players.map(p => p.Login)

    players.forEach(p => {
      const isNew = !this.state.lastPlayers.includes(p.Login) && this.state.lastPlayers.length > 0

      const div = document.createElement('div')
      div.className = 'list-item'

      div.innerHTML = `
                <div class="item-info">
                    <span class="player-login">${p.Login}</span>
                    ${isNew ? '<span class="badge new">NEW</span>' : ''}
                </div>
                <div class="actions">
                    <button class="btn-sm btn-secondary" onclick="app.spectate('${p.Login}')">
                      <i class="fa-solid fa-eye"></i> Spectate
                    </button>
                    <button class="btn-sm btn-secondary" onclick="app.kick('${p.Login}')">Kick</button>
                    <button class="btn-sm btn-danger" onclick="app.ban('${p.Login}')">Ban</button>
                </div>
            `
      list.appendChild(div)
    })

    this.state.lastPlayers = now
  },

  renderMaps(files, poolMaps, current) {
    const list = document.getElementById('maps-list')
    list.innerHTML = ''

    const fileSet = new Set(files)
    const rendered = new Set()

    const createItem = (file, isPool, isCurrent) => {
      const div = document.createElement('div')
      div.className = 'list-item'
      if (isCurrent) div.style.background = 'rgba(108, 92, 231, 0.1)'

      const cleanName = file.replace(/\.Map\.Gbx$/i, '')

      div.innerHTML = `
                <div class="item-info">
                    ${isCurrent ? '<i class="fa-solid fa-play" style="color: var(--accent); font-size: 0.8rem;"></i>' : ''}
                    <span>${cleanName}</span>
                    ${!fileSet.has(file) ? '<span class="badge">ToR Only</span>' : ''}
                    ${!isPool ? '<span class="badge">Not in Pool</span>' : ''}
                </div>
                <div>
                     <button class="btn-sm btn-secondary" onclick="app.nextMap('${file}')">
                        <i class="fa-solid fa-forward"></i> Queue
                     </button>
                     ${isPool ? `<button class="btn-sm btn-danger" onclick="app.removeMap('${file}')">
                        <i class="fa-solid fa-trash"></i>
                     </button>` : ''}
                </div>
            `
      return div
    }

    // 1. Pool Maps
    poolMaps.forEach(m => {
      const isActive = current && current.FileName === m.FileName
      list.appendChild(createItem(m.FileName, true, isActive))
      rendered.add(m.FileName)
    })

    // 2. File Maps (not in pool)
    files.forEach(file => {
      if (rendered.has(file)) return
      list.appendChild(createItem(file, false, false))
    })
  },

  // --- API Actions ---

  async kick(login) {
    if (!confirm(`Kick ${login}?`)) return
    await this.post('/players/kick', { login })
    this.showToast(`Kicked ${login}`)
    this.refresh()
  },

  async ban(login) {
    if (!confirm(`Ban ${login}?`)) return
    await this.post('/players/ban', { login })
    this.showToast(`Banned ${login}`)
    this.refresh()
  },

  async nextMap(file) {
    await this.post('/maps/next', { file })
    this.showToast(`Next map set: ${file}`)
  },

  // --- Server Management ---

  async skipMap() {
    if (!confirm('Skip to next map?')) return
    await this.post('/server/skip-map', {})
    this.showToast('Skipping to next map')
    setTimeout(() => this.refresh(), 1000)
  },

  async restartMap() {
    if (!confirm('Restart current map?')) return
    await this.post('/server/restart-map', {})
    this.showToast('Restarting map')
    setTimeout(() => this.refresh(), 1000)
  },

  async shuffleMaps() {
    if (!confirm('Shuffle all maps in the playlist?')) return
    await this.post('/maps/shuffle', {})
    this.showToast('Maps shuffled')
    setTimeout(() => this.refresh(), 1000)
  },

  async restartServer() {
    if (!confirm('Restart the game server? This will disconnect all players temporarily.')) return
    await this.post('/server/restart', {})
    this.showToast('Server restarting...')
    setTimeout(() => this.refresh(), 3000)
  },

  // --- Enhanced Player Actions ---

  async spectate(login) {
    await this.post('/players/spectate', { login })
    this.showToast(`${login} moved to spectator`)
    this.refresh()
  },

  async forceTeam(login, team) {
    const teamName = team === 0 ? 'Blue' : 'Red'
    await this.post('/players/force-team', { login, team })
    this.showToast(`${login} moved to ${teamName} team`)
    this.refresh()
  },

  // --- Map Management ---

  async removeMap(file) {
    if (!confirm(`Remove ${file} from playlist?`)) return
    await this.post('/maps/remove', { file })
    this.showToast(`Removed ${file}`)
    this.refresh()
  },

  // --- Chat ---

  async sendChat() {
    const input = document.getElementById('chat-input')
    const message = input.value.trim()
    if (!message) return

    await this.post('/chat/send', { message })
    input.value = ''
    this.showToast('Message sent')
  },

  // --- Renderers for New Features ---

  renderServerInfo(info) {
    document.getElementById('server-name').textContent = info.serverName || '-'
    document.getElementById('server-version').textContent = info.version?.Version || '-'
    document.getElementById('server-max-players').textContent = info.maxPlayers || '-'
    document.getElementById('server-max-spectators').textContent = info.maxSpectators || '-'
  },

  renderRankings(rankings) {
    const list = document.getElementById('rankings-list')
    list.innerHTML = ''

    if (!rankings || rankings.length === 0) {
      list.innerHTML = '<div style="padding: 20px; color: var(--text-muted); text-align: center;">No rankings available</div>'
      return
    }

    rankings.forEach((player, index) => {
      const div = document.createElement('div')
      div.className = 'ranking-item'

      const position = index + 1
      const posClass = position <= 3 ? 'top3' : ''
      const time = this.formatTime(player.BestTime)

      div.innerHTML = `
        <div class="ranking-position ${posClass}">#${position}</div>
        <div class="ranking-player">${player.Login}</div>
        <div class="ranking-time">${time}</div>
      `
      list.appendChild(div)
    })
  },

  formatTime(ms) {
    if (ms === -1 || ms === 0 || ms === undefined || ms === null || isNaN(ms)) return '-'
    const seconds = Math.floor(ms / 1000)
    const millis = ms % 1000
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins}:${secs.toString().padStart(2, '0')}.${millis.toString().padStart(3, '0')}`
  },

  renderChat(chatLines) {
    const container = document.getElementById('chat-messages')
    if (!chatLines || chatLines.length === 0) {
      container.innerHTML = '<div class="chat-placeholder">No messages yet. Chat will appear here.</div>'
      return
    }
    container.innerHTML = ''
    chatLines.forEach(line => {
      if (!line || typeof line !== 'string') return
      const div = document.createElement('div')
      div.className = 'chat-message'
      let author = '', text = ''
      if (line.includes(': ')) {
        const parts = line.split(': ')
        author = parts[0]
        text = parts.slice(1).join(': ')
      } else {
        author = 'Server'
        text = line
        div.classList.add('server')
      }
      const cleanText = text.replace(/\$[0-9a-fA-F]{3}/g, '').replace(/\$[wnoitsgz<>]/g, '');
      const cleanAuthor = author.replace(/\$[0-9a-fA-F]{3}/g, '').replace(/\$[wnoitsgz<>]/g, '');
      div.innerHTML = `<span class="chat-message-author">${this.escapeHtml(cleanAuthor)}:</span> <span class="chat-message-text">${this.escapeHtml(cleanText)}</span>`;
      container.appendChild(div)
    })
    container.scrollTop = container.scrollHeight
  },

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  },

  async post(endpoint, body) {
    await fetch(`${API}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    })
  },

  // --- Drag & Drop ---

  initDragAndDrop() {
    const zone = document.getElementById('drop-zone')
    const input = document.getElementById('mapFile')

      // Events
      ;['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        zone.addEventListener(eventName, preventDefaults, false)
      })

    function preventDefaults(e) {
      e.preventDefault()
      e.stopPropagation()
    }

    zone.addEventListener('dragenter', () => zone.classList.add('dragover'), false)
    zone.addEventListener('dragover', () => zone.classList.add('dragover'), false)
    zone.addEventListener('dragleave', () => zone.classList.remove('dragover'), false)
    zone.addEventListener('drop', handleDrop, false)

    function handleDrop(e) {
      zone.classList.remove('dragover')
      const dt = e.dataTransfer
      const files = dt.files
      handleFiles(files)
    }

    input.addEventListener('change', () => {
      handleFiles(input.files)
    })

    const handleFiles = async (files) => {
      if (!files.length) return

      const status = document.getElementById('uploadStatus')
      status.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Uploading...'

      const form = new FormData()
      let count = 0
      for (let i = 0; i < files.length; i++) {
        if (files[i].name.endsWith('.Map.Gbx')) {
          form.append('map', files[i])
          count++
        }
      }

      if (count === 0) {
        status.textContent = 'No .Map.Gbx files found'
        this.showToast('Invalid file type', 'error')
        return
      }

      try {
        const res = await fetch(`${API}/maps/upload`, {
          method: 'POST',
          body: form
        })

        if (res.ok) {
          const data = await res.json()
          status.innerHTML = `<span style="color: var(--success)">Successfully uploaded ${data.maps.length} maps</span>`
          this.showToast(`Uploaded ${data.maps.length} maps`)
          setTimeout(() => status.innerHTML = '', 4000)
          this.refresh()
        } else {
          throw new Error('Upload failed')
        }
      } catch (e) {
        status.textContent = 'Upload failed'
        this.showToast('Upload failed', 'error')
      }
    }
  }
}

// Make app global for HTML onclick handlers
window.app = app
