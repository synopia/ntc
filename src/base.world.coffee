Map = require('./map')

class World
  constructor: ->
    @map      = new Map()
    @bounds   = { max_x: 720, max_y: 480 }
    @pdt      = 0.0001
    @pdte     = new Date().getTime()
    @entities = []

    console.log("starting physic loop")
    setInterval =>
      @pdt  = (new Date().getTime() - @pdte)/ 1000.0
      @pdte = new Date().getTime()
      (entity.store() for entity in @entities)
      @on_update_physics?()
      @check_collisions()
    , 15

  draw: (ctx)->
    ctx.clearRect 0, 0, @bounds.max_x, @bounds.max_y
    block_size_x = @bounds.max_x / @map.size.x
    block_size_y = @bounds.max_y / @map.size.y
    ctx.fillStyle = "#555555"
    for x in [0..@map.size.x-1]
      for y in [0..@map.size.y-1]
        if @map.is_wall x, y
          ctx.fillRect x*block_size_x, y*block_size_y, block_size_x, block_size_y

  spawn: (entity, set_alive=true) ->
    @entities.push entity
    entity.alive = set_alive
    entity

  check_collisions: ->
    check_ground_collision = (entity) =>
      while entity.pos.x<0
        entity.pos.x += @bounds.max_x
      while entity.pos.y<0
        entity.pos.y += @bounds.max_y
      while entity.pos.x>=@bounds.max_x
        entity.pos.x -= @bounds.max_x;
      while entity.pos.y>=@bounds.max_y
        entity.pos.y -= @bounds.max_y;

      x = entity.pos.x * @map.size.x / @bounds.max_x
      y = entity.pos.y * @map.size.y / @bounds.max_y

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
          j += 1

      i+=1

    #@entities.filter (entity) -> entity.alive



module.exports = World