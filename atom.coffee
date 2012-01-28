Function.prototype.bind ?= (new_this) ->
  => @apply new_this, arguments


window.atom = atom = {}
atom.input = {
  _bindings: {}
  _down: {}
  _pressed: {}
  _released: []
  mouse: { x:0, y:0 }

  bind: (key, action) ->
    @_bindings[key] = action

  onkeydown: (e) ->
    action = @_bindings[eventCode e]
    return unless action

    @_pressed[action] = true unless @_down[action]
    @_down[action] = true

    e.stopPropagation()
    e.preventDefault()

  onkeyup: (e) ->
    action = @_bindings[eventCode e]
    return unless action
    @_released.push action
    e.stopPropagation()
    e.preventDefault()

  clearPressed: ->
    for action in @_released
      @_down[action] = false
    @_released = []
    @_pressed = {}

  pressed: (action) -> @_pressed[action]
  down: (action) -> @_down[action]

  onmousemove: (e) ->
    @mouse.x = e.pageX - atom.canvas.offsetLeft
    @mouse.y = e.pageY - atom.canvas.offsetTop
  onmousedown: (e) -> @onkeydown(e)
  onmouseup: (e) -> @onkeyup(e)
  onmousewheel: (e) ->
    @onkeydown e
    @onkeyup e
  oncontextmenu: (e) ->
    if @_bindings[atom.button.RIGHT]
      e.stopPropagation()
      e.preventDefault()
}

document.onkeydown = (args...) -> atom.input.onkeydown args...
document.onkeyup = (args...) -> atom.input.onkeyup args...

atom.button =
  LEFT: -1
  MIDDLE: -2
  RIGHT: -3
  WHEELDOWN: -4
  WHEELUP: -5
atom.key =
  TAB: 9
  ENTER: 13
  ESC: 27
  SPACE: 32
  LEFT_ARROW: 37
  UP_ARROW: 38
  RIGHT_ARROW: 39
  DOWN_ARROW: 40

for c in [65..90]
  atom.key[String.fromCharCode c] = c

eventCode = (e) ->
  if e.type == 'keydown' or e.type == 'keyup'
    e.keyCode
  else if e.type == 'mousedown' or e.type == 'mouseup'
    switch e.button
      when 0 then atom.button.LEFT
      when 1 then atom.button.MIDDLE
      when 2 then atom.button.RIGHT
  else if e.type == 'mousewheel'
    if e.wheel > 0
      atom.button.WHEELUP
    else
      atom.button.WHEELDOWN

atom.canvas = document.getElementsByTagName('canvas')[0]
#atom.canvas.style.position = "absolute"
#atom.canvas.style.top = "0"
#atom.canvas.style.left = "0"
atom.ctx = atom.canvas.getContext '2d'
#atom.gl = atom.canvas.getContext 'experimental-webgl'

atom.canvas.onmousemove = atom.input.onmousemove.bind(atom.input)
atom.canvas.onmousedown = atom.input.onmousedown.bind(atom.input)
atom.canvas.onmouseup = atom.input.onmouseup.bind(atom.input)
atom.canvas.onmousewheel = atom.input.onmousewheel.bind(atom.input)
atom.canvas.oncontextmenu = atom.input.oncontextmenu.bind(atom.input)

atom.audioContext = new webkitAudioContext?()

atom.loadSound = (url, callback) ->
  request = new XMLHttpRequest()
  request.open 'GET', url, true
  request.responseType = 'arraybuffer'

  request.onload = ->
    atom.audioContext.decodeAudioData request.response, (buffer) ->
      source = audioCtx.createBufferSource()
      source.buffer = buffer
      callback null, source
    , (error) ->
      callback error

  request.send()

requestAnimationFrame = window.requestAnimationFrame or
  window.webkitRequestAnimationFrame or
  window.mozRequestAnimationFrame or
  window.oRequestAnimationFrame or
  window.msRequestAnimationFrame or
  (callback) ->
    window.setTimeout(callback, 1000 / 60)

class Game
  constructor: ->
    @fps = 30
    @time = 0
  update: (dt) ->
  draw: ->
  run: ->
    @running = true

    self = @
    s = ->
      self.step()
      if self.running
        requestAnimationFrame s

    @last_step = Date.now()
    s()
  stop: ->
    @running = false
  step: ->
    now = Date.now()
    dt = (now - @last_step) / 1000
    @last_step = now
    @time += dt
    @update dt
    @draw()
    atom.input.clearPressed()

atom.Game = Game

