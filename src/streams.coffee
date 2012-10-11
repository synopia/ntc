class InputStream
  constructor: (stream) ->
    @stream = stream
    @pos    = 0

  read: (type=null)->
    res = @stream[@pos]
    @pos += 1
    res

  has_more:->
    @pos < @stream.length

class OutputStream
  constructor:->
    @stream = []

  write: (value, type=null)->
    @stream.push value

class Stream
  @input:(stream)->
    new InputStream(stream)

  @output:->
    new OutputStream()

module.exports = Stream


###
os = Stream.output()
os.write "X"
os.write 1
os.write 2.0

console.log JSON.stringify os.stream

ins = Stream.input(os.stream)
console.log(ins.read())
console.log(ins.read())
console.log(ins.read())
###
