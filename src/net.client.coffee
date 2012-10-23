class NetClient
  constructor: (socket)->
    @socket           = socket
    @inputs           = []
    @last_input_seq   = 0
    @last_input_time  = null

  process_input: (input) ->

  process_inputs: ->
    for input in @inputs when input.seq > @last_input_seq
      @process_input(input.inputs)

    if @inputs.length
      last_input = @inputs[@inputs.length-1]
      @last_input_time = last_input.time
      @last_input_seq  = last_input.seq



  emit: (channel, data)->
    console.log(data)
    @socket.emit channel, data

module.exports = NetClient