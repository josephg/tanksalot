
canvas = atom.canvas
ctx = atom.ctx
audioCtx = atom.audioContext

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

objectives = [
  {name:'win box', text:'Get the box'}
  {name:'win box', text:'Get the box'}
  {name:'win', text:'Make your team win'}
  {name:'win', text:'Make your team win'}
  {name:'last tank alive', text:'Be the last tank alive'}
  {name:'kill 3', text:'Kill 3 tanks'}
  {name:'win box timelimit', text:'Get the box within 15 seconds'}
  {name:'get shot by tank 1', text:'Get killed by the first tank'}
  {name:'win box', text:'Get the box'}
  {name:'pileup', text:'Cause a 3-tank pileup'}
]

sounds = {}

loaded = 0
didLoad = ->
  loaded++
  doneLoading() if loaded is 8 # number of sfx + 1

sfx =
  menu: 'tanks-tanks-tanks.mp3'
  shoot: 'shoot.wav'
  crash: 'crash.wav'
  explode: 'explode.wav'
  win: 'win.wav'
  youdie: 'youdie.wav'
  thud: 'thud.wav'

spritesheet = new Image
spritesheet.src = 'tanks.png'
spritesheet.onload = -> didLoad()

for s, url of sfx
  do (s, url) ->
    atom.loadSound "sounds/#{url}", (error, buffer) ->
      console.error error if error
      sounds[s] = buffer if buffer
      didLoad()

mixer = audioCtx.createGainNode()
mixer.connect audioCtx.destination

play = (name) ->
  return unless sounds[name]
  source = audioCtx.createBufferSource()
  source.buffer = sounds[name]
  source.connect mixer
  source.noteOn 0
  source

class Game extends atom.Game
  constructor: ->
    super()

    @background = []
    for i in [0..26]
      @background.push {
        tile: Math.floor Math.random()*5
        x: Math.floor(Math.random()*800)-400
        y: Math.floor(Math.random()*600)-300
      }

    canvas.width = 800
    canvas.height = 600
    ctx.translate 400, 300
    ctx.scale 1, -1
    @startMenu()

  startMenu: ->
    @state = 'menu'
    @menuMusic = play 'menu'
    @menuMusic?.loop = true

  startGame: ->
    @menuMusic?.noteOff 0
    @state = 'game'
    @mode = 'puzzle'
    @score = 0
    @tanks = []
    @nextId = 0
    @currentTank = null
    @reset()
    @round = 0

  endGame: ->
    @startMenu()

  reset: (winteam) ->
    @round++
    @nextId++ if @currentTank?.team != winteam and @mode != 'puzzle'

    if (@mode is 'puzzle' and @nextId is 10) or (@mode is 'sp' and @nextId is 40)
      @endGame()

    @currentTank =
      team: !!(@nextId % 2)
      id: @nextId++
      history: []

    @tanks.push @currentTank

    for tank in @tanks
      tank.x = 300
      if tank.team
        tank.angle = 0
      else
        tank.angle = TAU/2

      if tank.id >= 20
        tank.x += 50

      switch @mode
        when 'sp' or 'mp'
          tank.y = Math.floor((tank.id % 20)/2) * 50 - 225
        when 'puzzle'
          tank.y = Math.floor(tank.id/2) * 100 - 200

      if tank.team
        tank.x = -tank.x
        tank.y = -tank.y

      tank.alive = true
      tank.lastShot = -Infinity
      tank.distance = 10000

    @tick = 0
    @bullets = []

  update: (dt) ->
    return @updateMenu() if @state is 'menu'

    dt = 1/60

    if atom.input.pressed 'reset'
      @reset @currentTank.team

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
      actions |= 0x10
    if atom.input.down 'shoot'
      actions |= 0x20

    @currentTank.history.push actions


    for tank in @tanks
      continue unless tank.alive
      actions = tank.history[@tick]

      if actions & 1
        tank.distance++
        update dt, tank, 140
      else if actions & 2
        tank.distance--
        update dt, tank, -80

      if actions & 4
        tank.angle += 2 * dt
      if actions & 8
        tank.angle -= 2 * dt

      if (actions & 0x10 and tank.lastShot < @tick - 15) or (actions & 0x20 and tank.lastShot < @tick - 30)
        tank.lastShot = @tick
        @bullets.push
          x: tank.x
          y: tank.y
          angle: tank.angle
          team: tank.team
          owner: tank.id
          alive: true

        play 'shoot'


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

    # Tank vs wall
    for t in @tanks
      t.alive = false unless -385 < t.x < 385 and -285 < t.y < 285
    
    # Tank vs tank
    for a in @tanks
      for b in @tanks
        continue if a is b or !a.alive and !b.alive
        if within a, b, 30
          a.alive = b.alive = false
          play 'crash'

    # Tank vs bullet
    for t in @tanks
      for b in @bullets
        continue if b.owner is t.id
        if within t, b, 20
          if t.alive
            play 'explode'
          else
            play 'thud'

          t.alive = b.alive = false

    # All tanks dead
    aliveTanks = 0
    aliveTanks++ for t in @tanks when t.alive and t.history[@tick]?
    return @reset !@currentTank.team unless aliveTanks
    
    @tick++

    # Tank vs iwin button
    for t in @tanks
      if within t, {x:0, y:0}, 15
        if t.team == @currentTank.team
          play 'win'
        else
          play 'youdie'
        @reset t.team

  draw: ->
    return @drawMenu() if @state is 'menu'

    ctx.fillStyle = 'rgb(215,232,148)'
    ctx.fillRect -400, -300, 800, 600

    @drawBackground()

    ctx.save()
    ctx.scale 1, -1
    ctx.drawImage spritesheet, 32, 128, 32, 32, -16, -16, 32, 32
    ctx.restore()

    for bullet in @bullets
      ctx.save()
      ctx.translate bullet.x, bullet.y
      ctx.rotate bullet.angle + TAU/4

      frame = Math.floor(@tick / 3) % 3
      ctx.drawImage spritesheet, 32 + 8*frame, 96, 6, 18, -3, -9, 6, 18

      ctx.restore()


    for tank in @tanks
      ctx.save()
      ctx.translate tank.x, tank.y
      ctx.rotate tank.angle + TAU/4

      sprite = if tank.team then 0 else 1
      if tank.alive
        frame = Math.floor(tank.distance / 2) % 4
        ctx.drawImage spritesheet, 64 + frame*32, 96 + sprite*32, 32, 32, -16, -16, 32, 32
      else
        ctx.drawImage spritesheet, 64, 192 + sprite*32, 32, 32, -16, -16, 32, 32

      ctx.restore()

  drawBackground: ->
    for b in @background
      ctx.drawImage spritesheet, (80+16*b.tile)*2,16*2, 32, 32, b.x, b.y, 32, 32

  updateMenu: ->
    if atom.input.pressed 'start'
      if atom.input.mouse.x > 760 and atom.input.mouse.y > 560
        if mixer.gain.value
          mixer.gain.value = 0
        else
          mixer.gain.value = 1
      else
        @startGame()

  drawMenu: ->
    ctx.fillStyle = 'rgb(215,232,148)'
    ctx.fillRect -400, -300, 800, 600

    ctx.textAlign = 'center'
    ctx.fillStyle = 'black'
    ctx.save()
    ctx.scale 1, -1
    ctx.font = '60px KongtextRegular'
    ctx.fillText 'Tanks alot!', 0, 0, 600
    ctx.font = '20px KongtextRegular'
    ctx.fillText 'Click to start', 0, 100, 600
    ctx.restore()
   
atom.input.bind atom.key.LEFT_ARROW, 'left'
atom.input.bind atom.key.RIGHT_ARROW, 'right'
atom.input.bind atom.key.UP_ARROW, 'up'
atom.input.bind atom.key.DOWN_ARROW, 'down'
atom.input.bind atom.key.SPACE, 'shoot'
atom.input.bind atom.key.S, 'reset'

atom.input.bind atom.button.LEFT, 'start'

doneLoading = ->
  game = new Game()
  game.run()

