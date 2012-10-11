BaseEntity = require('../base.entity')

class Bullet extends BaseEntity
  constructor:(owner) ->
    super
    @owner = owner
    @radius = 6

  collide_with: (entity) ->
    @alive = false


module.exports = Bullet