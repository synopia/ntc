encodeFloat32 = (->
  arr = new Float32Array(1)
  char = new Uint8Array(arr.buffer)
  return (number)->
    arr[0] = number
    String.fromCharCode(char[0],char[1],char[2],char[3])
)()
decodeFloat32 = (->
  arr = new Float32Array(1)
  char = new Uint8Array(arr.buffer)
  return (str,offset)->
    for i in [0..3]
      char[i] = str.charCodeAt(offset+i)
    arr[0]
)()
encodeUint8 = (->
  arr = new Uint8Array(1)
  return (number)->
    arr[0] = number
    String.fromCharCode(arr[0])
)()
decodeUint8 = (->
  return (str,offset)->
    str.charCodeAt(offset)
)()

encodeUint16 = (->
  arr = new Uint16Array(1)
  char = new Uint8Array(arr.buffer)
  return (number)->
    arr[0] = number
    String.fromCharCode(char[0], char[1])
)()
decodeUint16 = (->
  arr = new Uint16Array(1)
  char = new Uint8Array(arr.buffer)
  return (str,offset)->
    char[0] = str.charCodeAt(offset+0)
    char[1] = str.charCodeAt(offset+1)
    arr[0]
)()


class InputStream
  constructor: (stream) ->
    @stream = stream
    @pos    = 0

  read_bool: ->
    c = @stream.charAt(@pos)
    @pos += 1
    c=="T"

  read_float: ->
    res = decodeFloat32(@stream, @pos)
    @pos += 4
    res

  read_byte: ->
    res = decodeUint8(@stream, @pos)
    @pos += 1
    res

  read_short: ->
    res = decodeUint16(@stream, @pos)
    @pos += 2
    res

  read_utf8: ->
    len = @read_short()
    res = @stream[@pos..@pos+len]
    @pos += len
    res

  read: ->
    @read_float()

  has_more:->
    @pos < @stream.length

class OutputStream
  constructor:->
    @stream = ""

  write_bool: (value)->
    @stream += if value==true then "T" else "F"

  write_float: (value)->
    @stream += encodeFloat32(value)

  write_byte: (value)->
    @stream += encodeUint8(value)

  write_short: (value)->
    @stream += encodeUint16(value)

  write_utf8: (value)->
    @write_short value.length
    @stream += value

  write: (value)->
    @write_float value

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
