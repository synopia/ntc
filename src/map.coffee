MAP = [
  'XX XXXXXXXXXXXXXXXXXXXXXXXXXXX    XX  XX',
  'XX     XXXXX            XXXXXX    XX  XX',
  'XX      XXXXX            XXXXXX   XX   X',
  'XXX                      XX       XX   X',
  'XX  XX                   XX XXX   XXX   ',
  '    XXX            XXX   XX XX    XXX  X',
  'XXXXXXX  XXXX  XX  XXX   XX XX          ',
  '         X                  XX          ',
  '         X                  XX          ',
  '         X                  XX          ',
  '         X         X        XX          ',
  'XXXX     XXXX  XXX XXX   XX XX    XXXXXX',
  'X  XX   XXXXX    X XXX   XX XXXX  X    X',
  '   XX   XXXXX    X XXX   XX   XX  X     ',
  'X       X   X            XXXX XX  X    X',
  'X  XX   X   XXX  XXXXX   XXXX XX  XXXX X',
  'X XX    X X XXX  XXX      XXX     XX   X',
  'XXX     X   X    XXX       XXX    XX  XX',
  '       XX   XX   XX   X    X            ',
  '        X             XX   X            ',
  '        XX           XXXX  X            ',
  'XXX XXX XXX        XXXXX   XXX  XXXX  XX',
  'XXX X    XX        X   X  XXXX    XX  XX',
  'XX  X     XX   XX XX   X     X    XX  XX',
  'XXX XX    XX   XX XXXX XX    XXX      XX',
  'X   XX    XX   XX XXX        X X      XX',
  'X X XXX   X                    X      XX',
  'X      X               XX    XXX  XX  XX',
  'XX XX  XX X           XXXXXXXX    XX  XX',
  'XX XXXXXXXXXXXXXXXXXXXXXXXXXXX    XX  XX'
]

class Map
  constructor: (map=MAP)->
    @map        = map
    @size       = { x:map[0].length, y:map.length }

  is_wall: (x, y)->
    _x = x & 0xffff
    _y = y & 0xffff

    _x = _x % @size.x
    _y = _y % @size.y

    @map[_y][_x]=='X'

  is_free: (x, y)->
    !@is_wall x, y

module.exports = Map

