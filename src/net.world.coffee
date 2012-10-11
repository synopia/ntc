window = global unless window
fps = 60
frame_time = 1000/fps


do ->
  last_time = 0
  for vendor in ['ms', 'moz', 'webkit', 'o']
    window.requestAnimationFrame = window["#{vendor}RequestAnimationFrame"]
    window.cancelAnimationFrame  = window["#{vendor}CancelAnimationFrame"] || window["#{vendor}CancelRequestAnimationFrame"]

  unless window.requestAnimationFrame
    window.requestAnimationFrame = (callback)->
      curr_time    = new Date().getTime()
      time_to_call = Math.max( 0, frame_time-(curr_time - last_time))
      id           = window.setTimeout ->
        callback( curr_time+time_to_call)
      , time_to_call
      last_time    = curr_time + time_to_call


  unless window.cancelAnimationFrame
    window.cancelAnimationFrame = (id)->
      clearTimeout(id)

class NetWorld
  constructor: ->
    @local_time = 0.016
    @_dt = new Date().getTime()
    @_dte = new Date().getTime()

    setInterval =>
      @_dt = new Date().getTime() - @_dte
      @_dte = new Date().getTime()
      @local_time += @_dt/1000.0
    , 4
    console.log("starting network loop")
    @update 0

  on_update: ->

  update: (t) ->
    @dt = if @lastframetime then ((t-@lastframetime) / 1000.0) else 0.016
    @lastframetime = t
    @on_update()
    @updateid = window.requestAnimationFrame (t)=> @update t


module.exports = NetWorld