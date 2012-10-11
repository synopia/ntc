
ClientGame = require('./game')

#io        = require('socket.io-client')

sio = io.connect "http://37.200.98.160::7007"

sio.on 'onconnect', (data)->
  userid = data.user_id

  sio.emit 'join', game_id:"funky"

sio.on 'onserverupdate', (data)->
#  console.log data

viewport = document.getElementById 'viewport'
viewport.width = 720
viewport.height = 480

game = new ClientGame(sio, viewport.getContext('2d'))
