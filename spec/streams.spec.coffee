Streams = require('../src/streams')

describe 'Streams', ->
  it "should work", ->
    os = Streams.output()
    os.write_bool(true)
    os.write_byte(1)
    os.write_short(2)
    os.write_float(3.14)
    os.write_utf8("BLABLA\xfcde")

    ins = Streams.input(os.stream)
    expect(ins.read_bool()).toEqual(true)
    expect(ins.read_byte()).toEqual(1)
    expect(ins.read_short()).toEqual(2)
    expect(ins.read_float().toFixed(2)).toEqual(3.14.toFixed(2))
    expect(ins.read_utf8()).toEqual("BLABLA\xfcde")