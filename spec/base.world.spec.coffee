Entity = require('../src/base.entity.coffee')
World  = require('../src/base.world.coffee')

describe 'World', ->
  beforeEach ->
    @world = new World({
      is_wall: (x,y)-> false
      is_free: (x,y)-> true
      size: { x:100, y:100 }
    })

  it "should collide entities", ->
    e1 = new Entity(); e1.set_pos 10,10,0; e1.radius = 10
    e2 = new Entity(); e2.set_pos 10,50,0; e2.radius = 10

    spyOn(e1, 'collide_with')
    spyOn(e2, 'collide_with')

    @world.spawn e1
    @world.spawn e2

    @world.on_update_physics = ->
      e1.move 0, 1, 0

    for i in [1..40]
      @world.inner_loop()

    expect(e1.pos.y).toEqual(29)
    expect(e1.collide_with).toHaveBeenCalledWith(e2)
    expect(e2.collide_with).toHaveBeenCalledWith(e1)

  it "should collide with world", ->
    @world.map = {
      is_wall: (x,y)-> y>20
      is_free: (x,y)-> !is_wall(x,y)
      size: { x:100, y:100 }
    }
    @world.bounds = { x:100, y:100 }
    e1 = new Entity(); e1.set_pos 0,0,0

    spyOn(e1, 'collide_with')

    @world.spawn e1

    @world.on_update_physics = ->
      e1.move 0, 1, 0

    for i in [1..30]
      @world.inner_loop()

    expect(e1.pos.y).toEqual 20
    expect(e1.collide_with).toHaveBeenCalledWith(@world.map)
