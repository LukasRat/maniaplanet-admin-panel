const gbxremote = require('gbxremote')

const RPC_HOST = '127.0.0.1'
const RPC_PORT = 5000
const RPC_LOGIN = 'SuperAdmin'
const RPC_PASSWORD = 'xc3412bdw'

async function testConnection() {
    console.log(`Connecting to ${RPC_HOST}:${RPC_PORT}...`)

    const client = gbxremote.createClient({ host: RPC_HOST, port: RPC_PORT })

    client.on('error', (err) => {
        console.error('RPC Client Error:', err.message)
    })

    try {
        await client.connect()
        console.log('Connected! Authenticating...')

        await client.query('Authenticate', [RPC_LOGIN, RPC_PASSWORD])
        console.log('Authenticated successfully!')

        const players = await client.query('GetPlayerList', [100, 0])
        console.log(`Players found: ${players.length}`)

        const maps = await client.query('GetChallengeList', [1000, 0])
        console.log(`Maps found: ${maps.length}`)

        process.exit(0)
    } catch (err) {
        console.error('Connection Failed:', err)
        process.exit(1)
    }
}

testConnection()
