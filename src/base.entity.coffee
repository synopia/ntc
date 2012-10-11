class Entity
  constructor: ->
    @pos    = { x:40, y:40, d:0 }
    @radius = 0
    @alive  = false
    @size   = { x:16, y:16, hx:8, hy:8 }

  store: ->
    @old_pos = { x:@pos.x, y:@pos.y, d:@pos.d }
  restore: ->
    @pos = { x:@old_pos.x, y:@old_pos.y, d:@old_pos.d }

  collide_with: (entity) ->

  move: (x_dir, y_dir, d_dir ) ->
    angle = @pos.d/ 180.0*Math.PI
    c = Math.cos(angle)
    s = Math.sin(angle)
    x = x_dir*c - y_dir*s
    y = y_dir*c + x_dir*s
    @pos.x += x
    @pos.y += y
    @pos.d += d_dir

  set_pos:(x, y, d)->
    @pos.x = x
    @pos.y = y
    @pos.d = d

  to_s: ->
    @pos.x+','+@pos.y+','+@pos.d


module.exports = Entity