BaseEntity = require('../base.entity')

class Tank extends BaseEntity
  constructor: ->
    super
    @radius = 10



module.exports = Tank