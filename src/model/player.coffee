Tank      = require('./tank')
Bullet    = require('./bullet')
NetClient = require('../net.client')

lerp = (p, n, t)->
  _t = Math.max(0, Math.min(1, t))
  p + _t * (n - p)

v3_lerp = (a,b,t)->
  {
    x: lerp(a.x, b.x, t),
    y: lerp(a.y, b.y, t),
    d: lerp(a.d, b.d, t)
  }
v2_lerp = (a,b,t)->
  {
    x: lerp(a.x, b.x, t),
    y: lerp(a.y, b.y, t),
    a: true
  }

COLOR_TABLE = [
  'rgba(255,0,0,0.8)',
  'rgba(0,0,255,0.8)',
  'rgba(0,255,0,0.8)',
  'rgba(255,0,255,0.8)',
  'rgba(255,255,255,0.8)',
  'rgba(255,255,0,0.8)',
  'rgba(255,255,0,0.8)',
  'rgba(255,0,255,0.8)',
  'rgba(255,255,0,0.8)'
]
class PlayerState
  constructor: (player=null) ->
    @bullets = ({alive:false,x:0,y:0} for i in [0..10])
    @load_from(player) if player

  load_from: (player) ->
    @id  = player.local_id
    @inp_seq  = player.last_input_seq
    @pos = {x:player.tank.pos.x, y:player.tank.pos.y, d:player.tank.pos.d }
    @turret_dir = player.turret_dir
    for b,i in player.bullets
      @bullets[i].alive = b.alive
      @bullets[i].x = b.pos.x
      @bullets[i].y = b.pos.y

  apply_to: (player) ->
    player.tank.pos.x = @pos.x
    player.tank.pos.y = @pos.y
    player.tank.pos.d = @pos.d
    player.turret_dir = @turret_dir
    for b,i in @bullets
      bullet = player.bullets[i]
      bullet.alive = b.alive
      bullet.pos.x = b.x
      bullet.pos.y = b.y

  pack: (output) ->
    output.write @id
    output.write @inp_seq
    output.write @pos.x
    output.write @pos.y
    output.write @pos.d
    output.write @turret_dir
    output.write (b for b in @bullets when b.alive).length
    for bullet, i in @bullets when bullet.alive
      output.write i
      output.write bullet.x
      output.write bullet.y

  unpack: (input)->
    @id  = input.read()
    @inp_seq = input.read()
    @pos = { x:input.read(), y:input.read(), d:input.read() }
    @turret_dir = input.read();
    bullet_count = input.read()
    if bullet_count>0
      for i in [1..bullet_count]
        id = input.read()
        @bullets[id].alive = true
        @bullets[id].x = input.read()
        @bullets[id].y = input.read()

  @lerp: (state0, state1, time_point)->
    ps = new PlayerState()
    ps.pos = v3_lerp(state0.pos, state1.pos, time_point)
    ps.turret_dir = lerp(state0.t, state1.t, time_point)
    ps.bullets = (v2_lerp(state0.bullets[i], state1.bullets[i], time_point) for i in [0..10] when state0.bullets[i].alive && state1.bullets[i].alive)

class Player extends NetClient

  constructor: (socket, world, local_id) ->
    super
    @local_id   = local_id
    @tank       = new Tank()
    @frags      = 0
    @deaths     = 0

    @tank.collide_with = (other)=>
      if other instanceof Bullet
        @deaths += 1
        other.owner.frags += 1

    @turret_dir = 0
    @bullets    = (new Bullet(@) for i in [0..10])
    @world      = world
    @color      = COLOR_TABLE[0]
    @last_shot  = 1

    world.spawn @tank
    @set_id local_id if local_id

    for b in @bullets
      world.spawn b, false


  set_id: (local_id)->
    @local_id = local_id
    @color    = COLOR_TABLE[local_id]


  draw: (ctx)->
    ctx.translate(@tank.pos.x, @tank.pos.y)
    ctx.rotate(@tank.pos.d/ 180.0*Math.PI)
    ctx.fillStyle = @color
    ctx.strokeStyle = "#000000"
    ctx.beginPath()
    ctx.arc(0,0,@tank.radius, 0, Math.PI*2, true)
    ctx.closePath()
    ctx.stroke();
    ctx.fillRect(-@tank.size.hx, -@tank.size.hy, @tank.size.x, @tank.size.y)

    ctx.rotate(@turret_dir/180.0*Math.PI)
    ctx.fillStyle = "rgba(0,0,0,1.0)"
    ctx.fillRect(-@tank.size.hx/ 2, 0, @tank.size.hx, @tank.size.y )
    ctx.rotate(-@turret_dir/180.0*Math.PI)

    ctx.rotate(-@tank.pos.d/ 180.0*Math.PI)
    ctx.translate(-@tank.pos.x, -@tank.pos.y)
    for bullet in @bullets when bullet.alive
      ctx.translate(bullet.pos.x, bullet.pos.y)
      ctx.fillStyle = "rgba(0,0,0,1.0)"
      ctx.fillRect(-2, -2, +4, +4)
      ctx.translate(-bullet.pos.x, -bullet.pos.y)

  process_physic_tick: ->
    for bullet in @bullets when bullet.alive
      bullet.pos.d = @tank.pos.d + @turret_dir
      bullet.move( 0, 1, 0 )

  process_input: (input)->
    @last_shot -= @world.pdt

    x_dir = 0
    y_dir = 0
    d_dir = 0
    t_dir = 0
    for char in input
      switch char
        when "u" then y_dir += 1
        when "d" then y_dir -= 1
        when "q" then x_dir -= 1
        when "e" then x_dir += 1
        when "l" then d_dir -= 1
        when "r" then d_dir += 1
        when "z" then t_dir -= 1
        when "c" then t_dir += 1
        when "s" then @fire()

    if input.length>0
      @tank.move( x_dir, y_dir, d_dir )
      @turret_dir += t_dir


  fire: ->
    return if @last_shot>0
    find_bullet = =>
      free = null
      for b in @bullets when !b.alive
        free = b
        break

      free

    bullet = find_bullet()
    bullet.alive = true
    bullet.set_pos @tank.pos.x, @tank.pos.y, @tank.pos.d+@turret_dir
    bullet.move 0, @tank.size.y*1.5, 0
    @last_shot = 1

  read_state: ->
    new PlayerState(@)

  write_state: (state)->
    state.apply_to @

module.exports = [Player, PlayerState]
