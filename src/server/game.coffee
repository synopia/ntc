World          = require('../base.world')
Entity         = require('../base.entity')
NetWorld       = require('../net.world')
Player         = require('../model/player')
Streams        = require('../streams')

class ServerGame
  constructor: (room)->
    @room      = room
    @world     = new World()
    @net_world = new NetWorld()
    @clients   = {}

    @net_world.on_update = =>
      @server_time = @net_world.local_time
      @last_state  = @pack()
      @room.emit 'onserverupdate', @last_state

    @world.on_update_physics = =>
      for id, client of @clients when client.connected
        client.process_physic_tick();
        client.process_inputs()
        client.inputs = []

  pack: ->
    world_state = Streams.output()
    client.pack(world_state) for id, client of @clients when client.connected
    {
      c: world_state.stream
      t: @server_time
    }

  join: (socket) ->
    local_id = @find_free_slot()
    client   = new Player socket, @world, local_id
    @clients[local_id] = client
    @clients[local_id].connected = true
    fake_lag = 0

    socket.on 'onclientupdate', (data)->
      if fake_lag>0
        setTimeout ->
          client.inputs.push data
        , fake_lag
      else
        client.inputs.push data

    socket.on 'disconnect', (data)=>
      @clients[local_id].connected = false

    socket.on 'ping', (data)->
      socket.emit 'ping', data

    socket.on 'fake_lag', (lag)->
      fake_lag = lag

    socket.emit 'invite', local_id:local_id

  find_free_slot: ->
    i = 1
    while i<100
      break unless @clients[i] && @clients[i].connected
      i += 1
    i

module.exports = ServerGame
