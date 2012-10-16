
log = if typeof window != 'undefined'
  (msg)->
    $('#log').prepend(msg+"\n")
else
  (msg)->
    console.log


module.exports = log
