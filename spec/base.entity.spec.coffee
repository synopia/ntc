Entity = require('../src/base.entity.coffee')

describe 'Entity', ->
  beforeEach ->
    @entity = new Entity()
    @entity.set_pos 10,10,0

  it "can move", ->
    @entity.move 0, 3, 90
    expect(@entity.pos.x).toEqual(10)
    expect(@entity.pos.y).toEqual(13)
    expect(@entity.pos.d).toEqual(90)

    @entity.move 0, 3, 90
    expect(@entity.pos.x).toEqual(7)
    expect(@entity.pos.y).toEqual(13)
    expect(@entity.pos.d).toEqual(180)

    @entity.move 0, 3, 90
    expect(@entity.pos.x).toEqual(7)
    expect(@entity.pos.y).toEqual(10)
    expect(@entity.pos.d).toEqual(270)

    @entity.move 0, 3, 90
    expect(@entity.pos.x).toEqual(10)
    expect(@entity.pos.y).toEqual(10)
    expect(@entity.pos.d).toEqual(360)

  it "can store/restore state", ->
    @entity.store()
    @entity.move 10,10,10
    expect(@entity.pos.x).toEqual(20)
    expect(@entity.pos.y).toEqual(20)
    expect(@entity.pos.d).toEqual(10)

    @entity.restore()
    expect(@entity.pos.x).toEqual(10)
    expect(@entity.pos.y).toEqual(10)
    expect(@entity.pos.d).toEqual(0)


