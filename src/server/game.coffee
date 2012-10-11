World          = require('../base.world')
Entity         = require('../base.entity')
NetWorld       = require('../net.world')
[Player, PlayerState] = require('../model/player')
Streams        = require('../streams')

class ServerGame
  constructor: ()->
    @world     = new World()
    @net_world = new NetWorld()
    @world.start()
    @net_world.start()
    @last_score_update = 0
    @clients   = {}

    @net_world.on_update = =>
      @server_time = @net_world.local_time
      @last_state  = @pack()
      @emit 'onserverupdate', @last_state
      if @server_time-@last_score_update>1
        @emit 'onscoreupdate', @pack_scores()
        @last_score_update = @server_time

    @world.on_update_physics = =>
      for id, client of @clients when client.connected
        client.process_physic_tick();
        client.process_inputs()
        client.inputs = []

  emit: (channel, data)->
    console.log "should be overwritten!"
  pack: ->
    world_state = Streams.output()
    client.read_state(world_state).pack(world_state) for id, client of @clients when client.connected
    {
      c: world_state.stream
      t: @server_time
    }

  pack_scores: ->
    world_state = Streams.output()
    for id, client of @clients when client.connected
      world_state.write_byte id
      client.pack_scores(world_state)
    world_state.stream

  join: (socket) ->
    local_id = @find_free_slot()
    client   = new Player socket, @world, local_id
    tile = @world.find_free_pos()
    client.tank.pos.x = tile.x
    client.tank.pos.y = tile.y
    @clients[local_id] = client
    @clients[local_id].connected = true
    fake_lag = 0
    socket.on 'nickname', (data)->
      client.nickname = data
    socket.on 'color', (data)->
      client.color = data

    socket.on 'onclientupdate', (data)->
      if fake_lag>0
        setTimeout ->
          client.inputs.push data
        , fake_lag
      else
        client.inputs.push data

    socket.on 'disconnect', (data)=>
      @clients[local_id].connected = false
      @emit 'oncldisc', {id:local_id}

    socket.on 'ping', (data)->
      socket.emit 'ping', data

    socket.on 'fake_lag', (lag)->
      fake_lag = lag

    socket.emit 'invite', local_id:local_id
    @emit 'onclconn', {id:local_id}

  find_free_slot: ->
    i = 1
    while i<100
      break unless @clients[i] && @clients[i].connected
      i += 1
    i

module.exports = ServerGame
