var Game, atom, c, eventCode, requestAnimationFrame, _base, _ref;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice;
if ((_ref = (_base = Function.prototype).bind) != null) {
  _ref;
} else {
  _base.bind = function(new_this) {
    return __bind(function() {
      return this.apply(new_this, arguments);
    }, this);
  };
};
window.atom = atom = {};
atom.input = {
  _bindings: {},
  _down: {},
  _pressed: {},
  _released: [],
  mouse: {
    x: 0,
    y: 0
  },
  bind: function(key, action) {
    return this._bindings[key] = action;
  },
  onkeydown: function(e) {
    var action;
    action = this._bindings[eventCode(e)];
    if (!action) {
      return;
    }
    if (!this._down[action]) {
      this._pressed[action] = true;
    }
    this._down[action] = true;
    e.stopPropagation();
    return e.preventDefault();
  },
  onkeyup: function(e) {
    var action;
    action = this._bindings[eventCode(e)];
    if (!action) {
      return;
    }
    this._released.push(action);
    e.stopPropagation();
    return e.preventDefault();
  },
  clearPressed: function() {
    var action, _i, _len, _ref2;
    _ref2 = this._released;
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      action = _ref2[_i];
      this._down[action] = false;
    }
    this._released = [];
    return this._pressed = {};
  },
  pressed: function(action) {
    return this._pressed[action];
  },
  down: function(action) {
    return this._down[action];
  },
  onmousemove: function(e) {
    this.mouse.x = e.pageX - atom.canvas.offsetLeft;
    return this.mouse.y = e.pageY - atom.canvas.offsetTop;
  },
  onmousedown: function(e) {
    return this.onkeydown(e);
  },
  onmouseup: function(e) {
    return this.onkeyup(e);
  },
  onmousewheel: function(e) {
    this.onkeydown(e);
    return this.onkeyup(e);
  },
  oncontextmenu: function(e) {
    if (this._bindings[atom.button.RIGHT]) {
      e.stopPropagation();
      return e.preventDefault();
    }
  }
};
document.onkeydown = function() {
  var args, _ref2;
  args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
  return (_ref2 = atom.input).onkeydown.apply(_ref2, args);
};
document.onkeyup = function() {
  var args, _ref2;
  args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
  return (_ref2 = atom.input).onkeyup.apply(_ref2, args);
};
atom.button = {
  LEFT: -1,
  MIDDLE: -2,
  RIGHT: -3,
  WHEELDOWN: -4,
  WHEELUP: -5
};
atom.key = {
  TAB: 9,
  ENTER: 13,
  ESC: 27,
  SPACE: 32,
  LEFT_ARROW: 37,
  UP_ARROW: 38,
  RIGHT_ARROW: 39,
  DOWN_ARROW: 40
};
for (c = 65; c <= 90; c++) {
  atom.key[String.fromCharCode(c)] = c;
}
eventCode = function(e) {
  if (e.type === 'keydown' || e.type === 'keyup') {
    return e.keyCode;
  } else if (e.type === 'mousedown' || e.type === 'mouseup') {
    switch (e.button) {
      case 0:
        return atom.button.LEFT;
      case 1:
        return atom.button.MIDDLE;
      case 2:
        return atom.button.RIGHT;
    }
  } else if (e.type === 'mousewheel') {
    if (e.wheel > 0) {
      return atom.button.WHEELUP;
    } else {
      return atom.button.WHEELDOWN;
    }
  }
};
atom.canvas = document.getElementsByTagName('canvas')[0];
atom.ctx = atom.canvas.getContext('2d');
atom.canvas.onmousemove = atom.input.onmousemove.bind(atom.input);
atom.canvas.onmousedown = atom.input.onmousedown.bind(atom.input);
atom.canvas.onmouseup = atom.input.onmouseup.bind(atom.input);
atom.canvas.onmousewheel = atom.input.onmousewheel.bind(atom.input);
atom.canvas.oncontextmenu = atom.input.oncontextmenu.bind(atom.input);
atom.audioContext = typeof webkitAudioContext === "function" ? new webkitAudioContext() : void 0;
atom.loadSound = function(url, callback) {
  var request;
  if (!atom.audioContext) {
    return callback('No audio support');
  }
  request = new XMLHttpRequest();
  request.open('GET', url, true);
  request.responseType = 'arraybuffer';
  request.onload = function() {
    return atom.audioContext.decodeAudioData(request.response, function(buffer) {
      return callback(null, buffer);
    }, function(error) {
      return callback(error);
    });
  };
  try {
    return request.send();
  } catch (e) {
    return callback(e.message);
  }
};
requestAnimationFrame = window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function(callback) {
  return window.setTimeout(callback, 1000 / 60);
};
Game = (function() {
  function Game() {
    this.fps = 30;
    this.time = 0;
  }
  Game.prototype.update = function(dt) {};
  Game.prototype.draw = function() {};
  Game.prototype.run = function() {
    var s, self;
    this.running = true;
    self = this;
    s = function() {
      self.step();
      if (self.running) {
        return requestAnimationFrame(s);
      }
    };
    this.last_step = Date.now();
    return s();
  };
  Game.prototype.stop = function() {
    return this.running = false;
  };
  Game.prototype.step = function() {
    var dt, now;
    now = Date.now();
    dt = (now - this.last_step) / 1000;
    this.last_step = now;
    this.time += dt;
    this.update(dt);
    this.draw();
    return atom.input.clearPressed();
  };
  return Game;
})();
atom.Game = Game;