
io        = require('socket.io')
express   = require('express')
UUID      = require('node-uuid')
http      = require('http')
ServerGame = require('./src/server/game')
fs        = require('fs')

GAME_PORT = process.env.PORT || 7007

app    = express()
server = http.createServer(app)

server.listen(GAME_PORT)
console.log("\t :: Express :: Listening on port #{GAME_PORT}")

app.get '/', (req, res) ->
  res.sendfile 'index.html'

app.get '/*', (req, res) ->
  fs.lstat req.params[0], (err,stats)->
    if not err
      res.sendfile req.params[0]
    else
      res.sendfile 'index.html'

sio = io.listen(server)

sio.configure ->
  @set 'log level', 0
  @set 'authorization', (handshakeData, callback)->
    callback(null, true)

games = {}

sio.on 'connection', (client)->
  game = null
  console.log "Client connected #{client}"
  client.user_id = UUID()
  client.emit 'onconnect', id:client.user_id

  client.on 'join', (data)->
    console.log "#{client.user_id} wants to join #{data.game_id}"
    game = games[data.game_id]
    if not game
      console.log " create new game"
      games[data.game_id] = game = new ServerGame
      game.emit = (channel, d)->
        sio.sockets.in("/"+data.game_id).emit(channel, d)

    client.join "/"+data.game_id
    client.leave ""
    game.join client

  client.on 'disconnect', ->
    console.log "Client disconnected #{client.user_id} from #{game}"


