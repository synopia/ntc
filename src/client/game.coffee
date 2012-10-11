World          = require('../base.world')
Entity         = require('../base.entity')
NetWorld       = require('../net.world')
LocalPlayer    = require('./local_player')
[Player, PlayerState] = require('../model/player')

RemotePlayer   = require('./remote_player')
Streams        = require('../streams')

log = (msg)->
  $("#log").prepend(msg+'\n')

class ClientGame
  constructor: (socket, ctx)->
    @ctx            = ctx
    @world          = new World()
    @net_world      = new NetWorld()
    @world.start()
    @net_world.start()
    @local_player   = new LocalPlayer socket, @world
    @server_updates = []
    @buffer_size    = 2
    @local_id       = -1
    @clients        = []
    @net_offset     = 100
    @server_time    = 0.016
    @client_time    = 0.016
    @player_info    = ("-" for i in [1..11])

    @remote_prediction = true
    @local_prediction  = true

    @net_ping    = 0.01
    @net_latency = 0.01
    @fake_lag    = 0

    @latest_server_update = null

    @create_debug_gui()

    socket.on "onscoreupdate", (data)=>
      @unpack_scores(data)

    socket.on "onclconn", (data)=>
      log("Player #{data.id} connected")

    socket.on "oncldisc", (data)=>
      log("#{@clients[data.id].nickname} disconnected")
      @clients[data.id].remove()
      @clients[data.id] = null
      @player_info[data.id] = "-"


    socket.on "onserverupdate", (data)=>
      @server_time = data.t
      @client_time = @server_time - (@net_offset/1000)
      @latest_server_update = data

      data.c = @unpack(data.c)

      if @local_prediction || @server_prediction
        @server_updates.push data
        if @server_updates.length>=600*@buffer_size
          @server_updates = @server_updates.splice(0,1)

      if @local_prediction
        @process_local_prediction_correction()
      else
        @local_player.apply data.c[@local_id] if data.c[@local_id]


    socket.on "invite", (data) =>
      @local_id = data.local_id
      @local_player.set_id @local_id
      if @clients[@local_id]
        @clients[@local_id].remove

      @clients[@local_id] = @local_player
      log "Use arrow keys to move, A and D to turn turret and space to shoot"

    @net_world.on_update = =>

      @world.draw @ctx

      @local_player.handle_input(@net_world.local_time)
      if @server_prediction
        @process_net_updates()
      else if @latest_server_update
        for id,client of @latest_server_update.c when id!=@local_id && @clients[id]
          @clients[id].write_state client

      for id, client of @clients
        client.draw(@ctx)

    @world.on_update_physics = =>
      @local_player.process_physic_tick();
      @local_player.process_inputs()
      unless @local_prediction
        @local_player.inputs = []

    @start_ping_timer()

  create_debug_gui: ->
    gui = new dat.GUI()
    player = gui.addFolder("Player")
    nickname = player.add(@local_player, 'nickname').listen()

    nickname.onChange (value)=>
      @local_player.socket.emit 'nickname', value

    color = player.addColor(@local_player, 'color').listen()
    color.onChange (value)=>
      @local_player.socket.emit 'color', value

    player.open()

    game = gui.addFolder("Game")
    for i in [1..10]
      game.add(@player_info, "#{i}").listen()

    game.open()

    network = gui.addFolder('Network')
    lag_control = network.add(@, 'fake_lag').step(0.001).min(0).max(2000).listen()
    lag_control.onChange (value)=>
      @local_player.socket.emit 'fake_lag', value

    network.add(@, 'server_time').listen()
    network.add(@net_world, 'local_time').listen()
    network.add(@, 'net_ping').listen()
    network.add(@, 'net_latency').listen()
    network.add(@, 'local_prediction').listen()
    network.add(@, 'remote_prediction').listen()


  process_net_updates: ->
    return if not @server_updates.length

    current_time = @client_time
    count        = @server_updates.length-1
    target       = null
    previous     = null

    if count>0
      for i in [0..(count-1)]
        point      = @server_updates[i]
        next_point = @server_updates[i+1]

        if current_time>point.t && current_time<next_point.t
          target = next_point
          previous = point
          break

    unless target
      target   = @server_updates[0]
      previous = @server_updates[0]

    if target && previous
      @target_time = target.t
      difference = @target_time - current_time
      max_difference = (target.t-previous.t)
      time_point = difference/max_difference

      if isNaN(time_point)     then time_point = 0
      if time_point==-Infinity then time_point = 0
      if time_point== Infinity then time_point = 0

      @lerp @server_updates[count].c, previous.c, target.c, time_point

  lerp: (latest, previous, target, time_point) ->
    max = Math.max( latest.max, Math.max(previous.max, target.max) )
    for id in [0..max] when id!=@local_id
      if previous[id] && target[id]
        lerp = PlayerState.lerp( previous[id], target[id], time_point )
        lerp.apply_to @clients[id]

  unpack: (server_data)->
    input = Streams.input(server_data)
    res = {}
    max = 0
    while input.has_more()
      player = new PlayerState()
      player.unpack input

      id = player.id
      res[id] = player

      @clients[id] ||= new RemotePlayer @world, id

      if id>max then max = id
    res.max = max
    res

  unpack_scores:(server_data)->
    input = Streams.input(server_data)
    while input.has_more()
      id = input.read_byte()
      @clients[id] ||= new RemotePlayer @world, id
      @clients[id].unpack_scores(input)
      @player_info[id] = "#{@clients[id].nickname} +#{@clients[id].frags} -#{@clients[id].deaths}"

  process_local_prediction_correction:->
    return if not @server_updates.length
    latest_server_data = @server_updates[-1..][0]
    my_server_state    = latest_server_data.c[@local_id]
    return if not my_server_state
    my_last_input_on_server = my_server_state.inp_seq
    if my_last_input_on_server
      lastinputseq_index = -1
      for input, i in @local_player.inputs
        if input.seq==my_last_input_on_server
          lastinputseq_index = i
          break

      if lastinputseq_index!=-1
        number_to_clear = Math.abs(lastinputseq_index-(-1))
        @local_player.inputs.splice(0, number_to_clear)

        my_server_state.apply_to @local_player
        @local_player.last_input_seq = lastinputseq_index
        @local_player.process_inputs()
        @world.check_collisions()

  start_ping_timer:->
    @local_player.socket.on 'ping', (data)=>
      @net_ping = new Date().getTime() - data
      @net_latency = @net_ping/2

    setInterval =>
      @last_ping_time = new Date().getTime() - @fake_lag
      @local_player.socket.emit('ping', @last_ping_time)
    , 1000

module.exports = ClientGame
