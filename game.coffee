canvas = atom.canvas
canvas.width = 800
canvas.height = 600
ctx = atom.ctx
ctx.translate 400, 300
ctx.scale 1, -1


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

# Not actually used...
objectives = [
  {name:'win box', text:'Get the box'}
  {name:'win box', text:'Get the box'}
  {name:'win', text:'Make your team win'}
  {name:'win', text:'Make your team win'}
  {name:'last alive', text:'Be the last tank alive'}
  {name:'kill 3', text:'Kill 3 tanks'}
  {name:'win box timelimit', text:'Get the box within 15 seconds'}
  {name:'killed by tank 1', text:'Get killed by the first tank'}
  {name:'win box', text:'Get the box'}
  {name:'pileup', text:'Cause a 3-tank pileup'}
]

sounds = {}

loaded = 0
didLoad = ->
  loaded++
  doneLoading() if loaded is 8 # MUST BE number of sfx + 1

window.onload = didLoad

muted = false

sfx =
#  menu: 'tanks-tanks-tanks.mp3'
#  game: 'game.mp3'
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

mixer = audioCtx?.createGain()
mixer?.connect audioCtx.destination


play = (name, time) ->
  return unless sounds[name] and audioCtx
  source = audioCtx.createBufferSource()
  source.buffer = sounds[name]
  source.connect mixer
  source.noteOn time ? 0
  source

toggleMute = ->
  if !muted
    muted = true
    mixer?.gain.value = 0
    e.volume = 0 for e in document.getElementsByTagName 'audio'
  else
    muted = false
    mixer?.gain.value = 1
    e.volume = 1 for e in document.getElementsByTagName 'audio'


class AttractScreen
  constructor: (@game) ->
    @music = document.getElementById 'menu'
    try
      unless @music?.currentTime
        @music?.currentTime = 0
        @music?.play()

  update: ->
    if atom.input.pressed('click') or atom.input.pressed('shoot')
      if atom.input.mouse.x > 700 and atom.input.mouse.y > 500
        toggleMute()
      else
        @game.enter new MainScreen @game

  draw: ->
    ctx.fillStyle = 'rgb(215,232,148)'
    ctx.fillRect -400, -300, 800, 600

    ctx.textAlign = 'center'
    ctx.fillStyle = 'rgb(32,70,49)'
    ctx.save()
    ctx.scale 1, -1
    ctx.font = '60px KongtextRegular'
    ctx.fillText 'Tanks a lot!', 0, -80, 600
    ctx.font = '20px KongtextRegular'
    ctx.fillText 'Press space to start', 0, 20, 600

    if !muted
      ctx.drawImage spritesheet, 94*2, 99*2, 20, 20, 360, 260, 20, 20
    else
      ctx.drawImage spritesheet, 81*2, 99*2, 20, 20, 360, 260, 20, 20

    ctx.drawImage spritesheet, 209*2, 10*2, 179*2, 38*2, -178, 130, 179*2, 38*2

    ctx.restore()


  exit: ->
    @music?.autoplay = false
    @music?.pause()

class MainScreen
  constructor: (@game) ->
    @background = []
    for i in [0..26]
      @background.push {
        tile: Math.floor Math.random()*5
        x: Math.floor(Math.random()*800)-400
        y: Math.floor(Math.random()*600)-300
      }

    @music = document.getElementById 'music'
    @state = ''  # 'game', 'game over', 'round over', 'round starting'
    @startGame()

  enter: ->
    try
      unless @music?.currentTime
        @music?.currentTime = 0
        @music?.play()

  exit: ->
    @music?.pause()

  startRound: ->
    @state = 'round starting'
    @stateTick = 0
    @reset()

  startGame: ->
    @mode = 'sp'
    @score = 0
    @tanks = []
    @nextId = 0
    @currentTank = null
    @startRound()
    @round = 0

  endGame: ->
    req = new XMLHttpRequest
    req.open 'POST', 'http://libris.nornagon.net/jca/tanks.cgi', true
    req.setRequestHeader 'Content-Type', 'application/json;charset=UTF-8'
    req.send JSON.stringify {
      tanks: @tanks.map (t) -> {
        id:t.id, team: t.team, history:t.history
      }
      score: @score
      round: @round
    }
    @state = 'game over'

  endRound: (winteam) ->
    if @currentTank.team != winteam
      @endGame()
    else
      @state = 'round over'

    @stateTick = 0

  reset: ->
    @round++
    #@nextId++ if @currentTank?.team != winteam and @mode != 'puzzle'

    if (@mode is 'puzzle' and @nextId is 10) or (@mode is 'sp' and @nextId is 40)
      @endGame()

    @currentTank =
      team: !!(@nextId % 2)
      id: @nextId++
      history: []#new Array 60*30

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

      tank.kills = 0

    @tick = 0
    @bullets = []

  update: (dt) ->
    dt = 1/60

    @stateTick++
    
    if atom.input.pressed('click') and atom.input.mouse.x > 700 and atom.input.mouse.y > 500
      toggleMute()

    if @state is 'game over' and @stateTick >= 80
      if atom.input.pressed('click') or atom.input.pressed('shoot')
        if atom.input.mouse.x > 700 and atom.input.mouse.y > 500
          toggleMute()
        else
          @startGame()
      #@updateMenu() # Do click/space detection
      #if @stateTick == 80
      #  @startMenuMusic()

    if @state is 'round starting'
      secs = 3 - Math.floor(@stateTick / 35)
      if secs < 0
        @state = 'game'

    if @state is 'round over'
      @score += 4 if @stateTick <= 25
      if @stateTick > 70
        @startRound()

    if atom.input.pressed 'reset'
      @reset @currentTank.team

    return unless @state is 'game'

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
      continue if !t.alive
      unless -385 < t.x < 385 and -285 < t.y < 285
        t.alive = false
        play 'crash'
    
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
            if b.owner == @currentTank.id
              @score += 10

            play 'explode'
            #console.log b.owner
            #@tanks[b.owner].kills++
            #if @tanks[b.owner].kills is 3 and b.owner == @currentTank.id
            #  @achieved 'kill 3'
            #if b.owner == 0 and t == @currentTank
            #  @achieved 'killed by tank 1'
          else
            play 'thud'

          t.alive = b.alive = false

    # All tanks dead
    aliveTanks = 0
    aliveTanks++ for t in @tanks when t.alive and t.history[@tick]?
    return @endRound null unless aliveTanks

    if aliveTanks == 1
      tank = t for t in @tanks when t.alive
      if tank == @currentTank
        @achieved 'last alive'
    
    @tick++

    # Tank vs iwin button
    for t in @tanks
      if within t, {x:0, y:0}, 32
        if t == @currentTank
          @achieved 'win box'
          @achieved 'win box timelimit' if @tick <= 60*15

        if t.team == @currentTank.team
          play 'win'
          @achieved 'win'
        else
          play 'youdie'
        @endRound t.team
  
  achieved: (thing) ->
    console.log 'done', thing unless thing is 'last alive'

  draw: ->
    ctx.fillStyle = 'rgb(215,232,148)'
    ctx.fillRect -400, -300, 800, 600

    @drawBackground()

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

      if tank is @currentTank
        ctx.lineWidth = 1.5
        if tank.team
          ctx.strokeStyle = 'rgb(32,70,49)'
        else
          ctx.strokeStyle = 'rgb(70,76,33)'
          
        ctx.strokeRect -18, -18, 36, 36

      sprite = if tank.team then 0 else 1
      if tank.alive
        frame = Math.floor(tank.distance / 2) % 4
        ctx.drawImage spritesheet, 64 + frame*32, 96 + sprite*32, 32, 32, -16, -16, 32, 32
      else
        ctx.drawImage spritesheet, 64, 192 + sprite*32, 32, 32, -16, -16, 32, 32

      ctx.restore()

    # iwin button
    ctx.save()
    ctx.scale 1, -1
    ctx.drawImage spritesheet, 224, 64, 64, 64, -32, -48, 64, 64
    #ctx.drawImage spritesheet, 32, 128, 32, 32, -16, -16, 32, 32
    ctx.restore()

    ctx.scale 1, -1
    ctx.textAlign = 'left'
    ctx.font = '20px KongtextRegular'
    ctx.fillStyle = 'rgb(32,70,49)'
    ctx.fillText 'SCORE:', 50, -260, 600

    ctx.textAlign = 'right'
    ctx.fillText "#{@score}", 280, -260, 600

    switch @state
      when 'round over'
        ctx.textAlign = 'center'
        ctx.font = '26px KongtextRegular'
        ctx.fillStyle = 'rgb(32,70,49)'
        ctx.fillText 'Mission Complete', 0, -110, 600
      when 'round starting'
        secs = 3 - Math.floor(@stateTick / 35)
        secs = 'GO!' if secs is 0

        ctx.textAlign = 'center'
        ctx.font = '70px KongtextRegular'
        ctx.fillStyle = 'rgb(32,70,49)'
        ctx.fillText "#{secs}", 0, -110, 600
      when 'game over'
        if (@stateTick % 30) < 15 or @stateTick >= 30*3
          ctx.textAlign = 'center'
          ctx.font = '50px KongtextRegular'
          ctx.fillStyle = 'rgb(32,70,49)'
          ctx.fillText "GAME OVER", 0, -110, 600

        if @stateTick >= 30 * 3
          ctx.font = '20px KongtextRegular'
          ctx.fillText 'Press space to retry', 0, 100, 600

    if !muted
      ctx.drawImage spritesheet, 94*2, 99*2, 20, 20, 360, 260, 20, 20
    else
      ctx.drawImage spritesheet, 81*2, 99*2, 20, 20, 360, 260, 20, 20
 
    ctx.scale 1, -1

  drawBackground: ->
    for b in @background
      ctx.drawImage spritesheet, (80+16*b.tile)*2,16*2, 32, 32, b.x, b.y, 32, 32

class Game extends atom.Game
  constructor: ->
    super()
    @screen = new AttractScreen @
  enter: (screen) ->
    @nextScreen = screen
  update: (dt) ->
    if @nextScreen?
      @screen.exit?()
      @screen = @nextScreen
      @nextScreen = null
      @screen.enter?()
    @screen.update dt
  draw: ->
    @screen.draw()

atom.input.bind atom.key.LEFT_ARROW, 'left'
atom.input.bind atom.key.RIGHT_ARROW, 'right'
atom.input.bind atom.key.UP_ARROW, 'up'
atom.input.bind atom.key.DOWN_ARROW, 'down'
atom.input.bind atom.key.SPACE, 'shoot'
atom.input.bind atom.key.S, 'reset'

atom.input.bind atom.button.LEFT, 'click'


doneLoading = ->
  game = new Game()
  game.run()
