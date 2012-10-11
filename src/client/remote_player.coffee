Player = require('../model/player')

class RemotePlayer extends Player
  constructor: (world, id)->
    super null, world, id


module.exports = RemotePlayer