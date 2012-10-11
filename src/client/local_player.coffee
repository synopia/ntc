[Player, PlayerState] = require('../model/player')
#THREEx = {
#  KeyboardState: ->
#    {
#      pressed: (key)->
#        key=='up' || key=='left'
#    }
#}
class LocalPlayer extends Player
  constructor: (socket, world) ->
    super
    @keyboard = new THREEx.KeyboardState()
    @input_seq = 0

  handle_input: (time)->
    input = []

    if @keyboard.pressed('up')
      input.push('u')
    if @keyboard.pressed('down')
      input.push('d')
    if @keyboard.pressed('left')
      input.push('l')
    if @keyboard.pressed('right')
      input.push('r')
    if @keyboard.pressed('A')
      input.push('z')
    if @keyboard.pressed('D')
      input.push('c')
    if @keyboard.pressed('space')
      input.push('s')

    if input.length>0

      #Update what sequence we are on now
      @input_seq += 1

      #Store the input state as a snapshot of what happened.
      @inputs.push { inputs : input, time : time, seq : @input_seq }
      @socket.emit "onclientupdate", { inputs : input, time : time, seq : @input_seq }


module.exports = LocalPlayer
