World  = require('../../src/base.world')
Streams = require('../../src/streams')
[Player, PlayerState] = require('../../src/model/player')

describe "PlayerState", ->
  beforeEach ->
    @world = new World()
    @player = new Player null, @world, 1

    @state = new PlayerState()
    @state.pos = { x:10, y:20, d:30 }
    @state.turret_dir = 40
    for b,i in @state.bullets
      b.alive = i%2==0
      b.x = i*100
      b.y = i


  it "loading and applying should work", ->
    orig_state = @player.read_state()

    @player.write_state(@state)

    expect(@player.tank.pos).toEqual( {x:10, y:20, d:30})
    expect(@player.turret_dir).toEqual(40)
    for b,i in @player.bullets
      expect(b.alive).toEqual(i%2==0)
      expect(b.pos.x).toEqual(i*100)
      expect(b.pos.y).toEqual(i)

  it "should write/read to/from stream", ->
    os = Streams.output()
    @state.pack os

    new_state = new PlayerState()
    inps = Streams.input os.stream
    new_state.unpack inps

    @player.write_state(new_state)

    expect(@player.tank.pos).toEqual( {x:10, y:20, d:30})
    expect(@player.turret_dir).toEqual(40)
    for b,i in @player.bullets
      expect(b.alive).toEqual(i%2==0)
      expect(b.pos.x).toEqual(i*100) if b.alive
      expect(b.pos.y).toEqual(i)     if b.alive

  it "should write/read multiple players", ->
    os = Streams.output()
    @state.pack os
    @state.pack os

    inps = Streams.input os.stream

    new_state1 = new PlayerState()
    new_state1.unpack inps
    new_state2 = new PlayerState()
    new_state2.unpack inps

    @player.write_state(new_state1)

    expect(@player.tank.pos).toEqual( {x:10, y:20, d:30})
    expect(@player.turret_dir).toEqual(40)
    for b,i in @player.bullets
      expect(b.alive).toEqual(i%2==0)
      expect(b.pos.x).toEqual(i*100) if b.alive
      expect(b.pos.y).toEqual(i)     if b.alive

    @player.write_state(new_state2)

    expect(@player.tank.pos).toEqual( {x:10, y:20, d:30})
    expect(@player.turret_dir).toEqual(40)
    for b,i in @player.bullets
      expect(b.alive).toEqual(i%2==0)
      expect(b.pos.x).toEqual(i*100) if b.alive
      expect(b.pos.y).toEqual(i)     if b.alive


  it "should", ->
    os = Streams.output()
    @state.pos.x=Math.PI
    @state.pos.y=Math.PI
    @state.pos.d=Math.PI
    @state.pack os

    console.log os.stream.length
