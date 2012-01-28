
canvas = atom.canvas
ctx = atom.ctx

id = 0
speed = 100

TAU = Math.PI * 2

update = (dt, obj, speed) ->
  obj.x += speed * dt * Math.cos obj.angle
  obj.y += speed * dt * Math.sin obj.angle

dist2 = (a, b) ->
  dx = a.x - b.x
  dy = a.y - b.y
  dx * dx + dy * dy

within = (a, b, dist) ->
  dist2(a, b) < dist * dist

class Game extends atom.Game
  constructor: ->
    super()

    canvas.width = 800
    canvas.height = 600

    ctx.translate 400, 300
    ctx.scale 1, -1

    @tanks = []
    @reset()

  reset: (winteam) ->
    id++ if @currentTank?.team != winteam

    @currentTank =
      team: !!(id % 2)
      id: id++
      history: []
      alive: true

    @tanks.push @currentTank

    for tank in @tanks
      if tank.team
        tank.x = -350
        tank.angle = 0
      else
        tank.x = 350
        tank.angle = TAU/2

      tank.y = Math.floor(tank.id/2) * 40 - 250
      tank.y = -tank.y if tank.team
      tank.alive = true

    @tick = 0
    @bullets = []

  update: (dt) ->
    dt = 1/60

    if atom.input.pressed 'reset'
      @reset()

    actions = 0

    if atom.input.down 'up'
      actions |= 1
    else if atom.input.down 'down'
      actions |= 2

    if atom.input.down 'left'
      actions |= 4
    if atom.input.down 'right'
      actions |= 8

    if atom.input.pressed 'shoot'
      actions |= 16

    @currentTank.history.push actions


    for tank in @tanks
      continue unless tank.alive
      actions = tank.history[@tick]

      if actions & 1
        update dt, tank, 140
      else if actions & 2
        update dt, tank, -80

      if actions & 4
        tank.angle += 2 * dt
      if actions & 8
        tank.angle -= 2 * dt

      if actions & 16
        @bullets.push
          x: tank.x
          y: tank.y
          angle: tank.angle
          team: tank.team
          owner: tank.id
          alive: true

    i = 0
    # Update particles and delete any that have expired
    while i < @bullets.length
      bullet = @bullets[i]
      update dt, bullet, 300

      if !(-450 < bullet.x < 450 and -350 < bullet.y < 350) or !bullet.alive
        @bullets[i] = @bullets[@bullets.length - 1]
        @bullets.length--
      else
        i++

    
    # Tank vs tank
    for a in @tanks
      for b in @tanks
        continue if a is b
        if within a, b, 30
          a.alive = b.alive = false

    # Tank vs bullet
    for t in @tanks
      for b in @bullets
        continue if b.owner is t.id
        if within t, b, 20
          t.alive = b.alive = false

    @tick++

    # Tank vs iwin button
    for t in @tanks
      if within t, {x:0, y:0}, 15
        @reset t.team

    aliveTanks = 0
    aliveTanks++ for t in @tanks when t.alive
    @reset !@currentTank.team unless aliveTanks
    
  draw: ->
    #ctx.fillStyle = "hsl(#{@backgroundHue},54%,76%)"
    ctx.fillStyle = '#ccc'
    ctx.fillRect -400, -300, 800, 600
 
    ctx.fillStyle = 'yellow'
    ctx.fillRect -15, -15, 30, 30

    for tank in @tanks
      ctx.save()
      ctx.translate tank.x, tank.y
      ctx.rotate tank.angle
      ctx.fillStyle = if tank.alive
        if tank is @currentTank
          if tank.team then 'darkblue' else 'darkred'
        else if tank.team
          'blue'
        else
          'red'
      else
        # Dead
        '#555'

      ctx.fillRect -15, -15, 30, 30
      ctx.restore()

    for bullet in @bullets
      ctx.save()
      ctx.translate bullet.x, bullet.y
      ctx.rotate bullet.angle
      ctx.fillStyle = 'black'

      ctx.fillRect -5, -5, 10, 10
      ctx.restore()
   
atom.input.bind atom.key.LEFT_ARROW, 'left'
atom.input.bind atom.key.RIGHT_ARROW, 'right'
atom.input.bind atom.key.UP_ARROW, 'up'
atom.input.bind atom.key.DOWN_ARROW, 'down'
atom.input.bind atom.key.SPACE, 'shoot'
atom.input.bind atom.key.S, 'reset'
game = new Game()
game.run()

