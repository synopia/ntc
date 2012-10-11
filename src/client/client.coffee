
ClientGame = require('./game')

url_pattern = ///
  ^(http://.*:[0-9]+/)(.*)$
///

[url, room] = window.location.href.match(url_pattern)[1..2]

room ||= "default"

sio = io.connect url

sio.on 'onconnect', (data)->
  userid = data.user_id

  sio.emit 'join', game_id:room

sio.on 'onserverupdate', (data)->
#  console.log data

viewport = document.getElementById 'viewport'
viewport.width = 720
viewport.height = 480

game = new ClientGame(sio, viewport.getContext('2d'))
