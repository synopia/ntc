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


  pack: (output)->
    super
    output.write @local_id
    output.write @tank.pos.x
    output.write @tank.pos.y
    output.write @tank.pos.d
    output.write @turret_dir
    output.write @frags
    output.write @deaths
    for bullet in @bullets
      output.write bullet.alive
      if bullet.alive
        output.write bullet.pos.x
        output.write bullet.pos.y


  @unpack: (input)->
    res    = super
    res.id =  input.read()
    res.p  = {x:input.read(),y: input.read(), d:input.read()}
    res.t  = input.read()
    res.b  = []
    res.f  = input.read()
    res.d  = input.read()
    for i in [0..10]
      a = input.read()
      if a==true
        x = input.read()
        y = input.read()
        res.b.push {a:true,x:x, y:y}
      else
        res.b.push {a:false}

    res

  apply: (data)->
    super
    @tank.pos.x = data.p.x
    @tank.pos.y = data.p.y
    @tank.pos.d = data.p.d
    @turret_dir = data.t
    @frags      = data.f
    @deaths     = data.d
    for b,i in data.b
      @bullets[i].alive = b.a
      if b.a
        @bullets[i].set_pos b.x, b.y, @tank.pos.d

  @lerp: (data0, data1, time_point)->
    res = {
      id: data0.id,
      p: v3_lerp(data0.p, data1.p, time_point),
      b: (v2_lerp(data0.b[i], data1.b[i], time_point) for i in [0..10] when data0.b[i].alive && data1.b[i].alive),
      t: lerp(data0.t, data1.t, time_point),
      f: data1.f,
      d: data1.d
    }
    res


module.exports = Player
