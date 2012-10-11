Map = require('./map')

class World
  constructor: (map=new Map())->
    @map      = map
    @bounds   = { x: 720, y: 480 }
    @pdt      = 0.0001
    @pdte     = new Date().getTime()
    @entities = []


  draw: (ctx)->
    ctx.clearRect 0, 0, @bounds.x, @bounds.y
    block_size_x = @bounds.x / @map.size.x
    block_size_y = @bounds.y / @map.size.y
    ctx.fillStyle = "#555555"
    for x in [0..@map.size.x-1]
      for y in [0..@map.size.y-1]
        if @map.is_wall x, y
          ctx.fillRect x*block_size_x, y*block_size_y, block_size_x, block_size_y

  find_free_pos: ->
    x = 0
    y = 0
    while @map.is_wall(x, y)
      x = Math.random()*@map.size.x
      y = Math.random()*@map.size.y
    { x:x*@bounds.x / @map.size.x, y:y*@bounds.y / @map.size.y }

  start: ->
    console.log("starting physic loop")
    @physic_loop = setInterval =>
      @inner_loop()
    , 15

  stop: ->
    console.log("stopping physic loop")
    clearInterval @physic_loop

  inner_loop: ->
    @pdt  = (new Date().getTime() - @pdte)/ 1000.0
    @pdte = new Date().getTime()

    (entity.store() for entity in @entities)
    @on_update_physics?()
    @check_collisions()

  spawn: (entity, set_alive=true) ->
    @entities.push entity
    entity.alive = set_alive
    entity

  check_collisions: ->
    check_ground_collision = (entity) =>
      while entity.pos.x<0
        entity.pos.x += @bounds.x
      while entity.pos.y<0
        entity.pos.y += @bounds.y
      while entity.pos.x>=@bounds.x
        entity.pos.x -= @bounds.x;
      while entity.pos.y>=@bounds.y
        entity.pos.y -= @bounds.y;

      x = entity.pos.x * @map.size.x / @bounds.x
      y = entity.pos.y * @map.size.y / @bounds.y

      @map.is_wall( x, y )

    check_entity_collision = (entity0, entity1) ->
      dist_sq = (entity0.pos.x-entity1.pos.x)*(entity0.pos.x-entity1.pos.x) + (entity0.pos.y-entity1.pos.y)*(entity0.pos.y-entity1.pos.y)
      max_dist_sq = (entity0.radius+entity1.radius)*(entity0.radius+entity1.radius)
      dist_sq<=max_dist_sq

    for i, entity of @entities
      collision = entity.alive && check_ground_collision(entity)
      if collision
        entity.restore()
        entity.collide_with @map

    count=@entities.length
    i = 0
    while i<count
      if @entities[i].alive
        j = i+1
        while j<count
          if @entities[j].alive

            collision = check_entity_collision( @entities[i], @entities[j])
            if collision
              @entities[i].collide_with( @entities[j] )
              @entities[j].collide_with( @entities[i] )

              @entities[i].restore()
              @entities[j].restore()
          j += 1

      i+=1

    #@entities.filter (entity) -> entity.alive



module.exports = World