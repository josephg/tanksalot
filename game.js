var Game, TAU, audioCtx, canvas, ctx, didLoad, dist2, doneLoading, id, loaded, mixer, muted, objectives, play, s, sfx, sounds, speed, spritesheet, update, url, within, _fn;
var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
};
canvas = atom.canvas;
if (/Windows.*Chrome\/16/.test(navigator.userAgent)) {
  canvas.style.borderRadius = 0;
}
ctx = atom.ctx;
audioCtx = atom.audioContext;
id = 0;
speed = 100;
TAU = Math.PI * 2;
update = function(dt, obj, speed) {
  obj.x += speed * dt * Math.cos(obj.angle);
  return obj.y += speed * dt * Math.sin(obj.angle);
};
dist2 = function(a, b) {
  var dx, dy;
  dx = a.x - b.x;
  dy = a.y - b.y;
  return dx * dx + dy * dy;
};
within = function(a, b, dist) {
  return dist2(a, b) < dist * dist;
};
objectives = [
  {
    name: 'win box',
    text: 'Get the box'
  }, {
    name: 'win box',
    text: 'Get the box'
  }, {
    name: 'win',
    text: 'Make your team win'
  }, {
    name: 'win',
    text: 'Make your team win'
  }, {
    name: 'last alive',
    text: 'Be the last tank alive'
  }, {
    name: 'kill 3',
    text: 'Kill 3 tanks'
  }, {
    name: 'win box timelimit',
    text: 'Get the box within 15 seconds'
  }, {
    name: 'killed by tank 1',
    text: 'Get killed by the first tank'
  }, {
    name: 'win box',
    text: 'Get the box'
  }, {
    name: 'pileup',
    text: 'Cause a 3-tank pileup'
  }
];
sounds = {};
loaded = 0;
didLoad = function() {
  loaded++;
  if (loaded === 8) {
    return doneLoading();
  }
};
window.onload = didLoad;
muted = false;
sfx = {
  shoot: 'shoot.wav',
  crash: 'crash.wav',
  explode: 'explode.wav',
  win: 'win.wav',
  youdie: 'youdie.wav',
  thud: 'thud.wav'
};
spritesheet = new Image;
spritesheet.src = 'tanks.png';
spritesheet.onload = function() {
  return didLoad();
};
_fn = function(s, url) {
  return atom.loadSound("sounds/" + url, function(error, buffer) {
    if (error) {
      console.error(error);
    }
    if (buffer) {
      sounds[s] = buffer;
    }
    return didLoad();
  });
};
for (s in sfx) {
  url = sfx[s];
  _fn(s, url);
}
mixer = audioCtx != null ? audioCtx.createGainNode() : void 0;
if (mixer != null) {
  mixer.connect(audioCtx.destination);
}
play = function(name, time) {
  var source;
  if (!(sounds[name] && audioCtx)) {
    return;
  }
  source = audioCtx.createBufferSource();
  source.buffer = sounds[name];
  source.connect(mixer);
  source.noteOn(time != null ? time : 0);
  return source;
};
Game = (function() {
  __extends(Game, atom.Game);
  function Game() {
    var i;
    Game.__super__.constructor.call(this);
    this.background = [];
    for (i = 0; i <= 26; i++) {
      this.background.push({
        tile: Math.floor(Math.random() * 5),
        x: Math.floor(Math.random() * 800) - 400,
        y: Math.floor(Math.random() * 600) - 300
      });
    }
    canvas.width = 800;
    canvas.height = 600;
    ctx.translate(400, 300);
    ctx.scale(1, -1);
    this.menuMusic = document.getElementById('menu');
    this.gameMusic = document.getElementById('music');
    this.startMenuMusic();
    this.state = 'menu';
  }
  Game.prototype.startMenuMusic = function() {
    var _ref, _ref2, _ref3, _ref4;
    if ((_ref = this.gameMusic) != null) {
      _ref.pause();
    }
    try {
      if (!((_ref2 = this.menuMusic) != null ? _ref2.currentTime : void 0)) {
        if ((_ref3 = this.menuMusic) != null) {
          _ref3.currentTime = 0;
        }
        return (_ref4 = this.menuMusic) != null ? _ref4.play() : void 0;
      }
    } catch (_e) {}
  };
  Game.prototype.startGameMusic = function() {
    var _ref, _ref2, _ref3, _ref4, _ref5;
    if ((_ref = this.menuMusic) != null) {
      _ref.autoplay = false;
    }
    if ((_ref2 = this.menuMusic) != null) {
      _ref2.pause();
    }
    try {
      if (!((_ref3 = this.gameMusic) != null ? _ref3.currentTime : void 0)) {
        if ((_ref4 = this.gameMusic) != null) {
          _ref4.currentTime = 0;
        }
        return (_ref5 = this.gameMusic) != null ? _ref5.play() : void 0;
      }
    } catch (_e) {}
  };
  Game.prototype.startRound = function() {
    this.state = 'round starting';
    this.stateTick = 0;
    return this.reset();
  };
  Game.prototype.startGame = function() {
    var _ref;
    if ((_ref = this.menuMusic) != null) {
      _ref.pause();
    }
    this.startGameMusic();
    this.mode = 'sp';
    this.score = 0;
    this.tanks = [];
    this.nextId = 0;
    this.currentTank = null;
    this.startRound();
    return this.round = 0;
  };
  Game.prototype.endGame = function() {
    var req;
    req = new XMLHttpRequest;
    req.open('POST', 'http://libris.nornagon.net/jca/tanks.cgi', true);
    req.setRequestHeader('Content-Type', 'application/json;charset=UTF-8');
    req.send(JSON.stringify({
      tanks: this.tanks.map(function(t) {
        return {
          id: t.id,
          team: t.team,
          history: t.history
        };
      }),
      score: this.score,
      round: this.round
    }));
    return this.state = 'game over';
  };
  Game.prototype.endRound = function(winteam) {
    if (this.currentTank.team !== winteam) {
      this.endGame();
    } else {
      this.state = 'round over';
    }
    return this.stateTick = 0;
  };
  Game.prototype.reset = function() {
    var tank, _i, _len, _ref;
    this.round++;
    if ((this.mode === 'puzzle' && this.nextId === 10) || (this.mode === 'sp' && this.nextId === 40)) {
      this.endGame();
    }
    this.currentTank = {
      team: !!(this.nextId % 2),
      id: this.nextId++,
      history: []
    };
    this.tanks.push(this.currentTank);
    _ref = this.tanks;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      tank = _ref[_i];
      tank.x = 300;
      if (tank.team) {
        tank.angle = 0;
      } else {
        tank.angle = TAU / 2;
      }
      if (tank.id >= 20) {
        tank.x += 50;
      }
      switch (this.mode) {
        case 'sp' || 'mp':
          tank.y = Math.floor((tank.id % 20) / 2) * 50 - 225;
          break;
        case 'puzzle':
          tank.y = Math.floor(tank.id / 2) * 100 - 200;
      }
      if (tank.team) {
        tank.x = -tank.x;
        tank.y = -tank.y;
      }
      tank.alive = true;
      tank.lastShot = -Infinity;
      tank.distance = 10000;
      tank.kills = 0;
    }
    this.tick = 0;
    return this.bullets = [];
  };
  Game.prototype.update = function(dt) {
    var a, actions, aliveTanks, b, bullet, i, secs, t, tank, _i, _j, _k, _l, _len, _len2, _len3, _len4, _len5, _len6, _len7, _len8, _len9, _m, _n, _o, _p, _q, _ref, _ref10, _ref11, _ref12, _ref13, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9, _results;
    dt = 1 / 60;
    this.stateTick++;
    if (this.state === 'menu') {
      return this.updateMenu();
    }
    if (atom.input.pressed('click') && atom.input.mouse.x > 700 && atom.input.mouse.y > 500) {
      this.toggleMute();
    }
    if (this.state === 'game over' && this.stateTick >= 80) {
      this.updateMenu();
    }
    if (this.state === 'round starting') {
      secs = 3 - Math.floor(this.stateTick / 35);
      if (secs < 0) {
        this.state = 'game';
      }
    }
    if (this.state === 'round over') {
      if (this.stateTick <= 25) {
        this.score += 4;
      }
      if (this.stateTick > 70) {
        this.startRound();
      }
    }
    if (atom.input.pressed('reset')) {
      this.reset(this.currentTank.team);
    }
    if (this.state !== 'game') {
      return;
    }
    actions = 0;
    if (atom.input.down('up')) {
      actions |= 1;
    } else if (atom.input.down('down')) {
      actions |= 2;
    }
    if (atom.input.down('left')) {
      actions |= 4;
    }
    if (atom.input.down('right')) {
      actions |= 8;
    }
    if (atom.input.pressed('shoot')) {
      actions |= 0x10;
    }
    if (atom.input.down('shoot')) {
      actions |= 0x20;
    }
    this.currentTank.history.push(actions);
    _ref = this.tanks;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      tank = _ref[_i];
      if (!tank.alive) {
        continue;
      }
      actions = tank.history[this.tick];
      if (actions & 1) {
        tank.distance++;
        update(dt, tank, 140);
      } else if (actions & 2) {
        tank.distance--;
        update(dt, tank, -80);
      }
      if (actions & 4) {
        tank.angle += 2 * dt;
      }
      if (actions & 8) {
        tank.angle -= 2 * dt;
      }
      if ((actions & 0x10 && tank.lastShot < this.tick - 15) || (actions & 0x20 && tank.lastShot < this.tick - 30)) {
        tank.lastShot = this.tick;
        this.bullets.push({
          x: tank.x,
          y: tank.y,
          angle: tank.angle,
          team: tank.team,
          owner: tank.id,
          alive: true
        });
        play('shoot');
      }
    }
    i = 0;
    while (i < this.bullets.length) {
      bullet = this.bullets[i];
      update(dt, bullet, 300);
      if (!((-450 < (_ref2 = bullet.x) && _ref2 < 450) && (-350 < (_ref3 = bullet.y) && _ref3 < 350)) || !bullet.alive) {
        this.bullets[i] = this.bullets[this.bullets.length - 1];
        this.bullets.length--;
      } else {
        i++;
      }
    }
    _ref4 = this.tanks;
    for (_j = 0, _len2 = _ref4.length; _j < _len2; _j++) {
      t = _ref4[_j];
      if (!t.alive) {
        continue;
      }
      if (!((-385 < (_ref5 = t.x) && _ref5 < 385) && (-285 < (_ref6 = t.y) && _ref6 < 285))) {
        t.alive = false;
        play('crash');
      }
    }
    _ref7 = this.tanks;
    for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
      a = _ref7[_k];
      _ref8 = this.tanks;
      for (_l = 0, _len4 = _ref8.length; _l < _len4; _l++) {
        b = _ref8[_l];
        if (a === b || !a.alive && !b.alive) {
          continue;
        }
        if (within(a, b, 30)) {
          a.alive = b.alive = false;
          play('crash');
        }
      }
    }
    _ref9 = this.tanks;
    for (_m = 0, _len5 = _ref9.length; _m < _len5; _m++) {
      t = _ref9[_m];
      _ref10 = this.bullets;
      for (_n = 0, _len6 = _ref10.length; _n < _len6; _n++) {
        b = _ref10[_n];
        if (b.owner === t.id) {
          continue;
        }
        if (within(t, b, 20)) {
          if (t.alive) {
            if (b.owner === this.currentTank.id) {
              this.score += 10;
            }
            play('explode');
          } else {
            play('thud');
          }
          t.alive = b.alive = false;
        }
      }
    }
    aliveTanks = 0;
    _ref11 = this.tanks;
    for (_o = 0, _len7 = _ref11.length; _o < _len7; _o++) {
      t = _ref11[_o];
      if (t.alive && (t.history[this.tick] != null)) {
        aliveTanks++;
      }
    }
    if (!aliveTanks) {
      return this.endRound(null);
    }
    if (aliveTanks === 1) {
      _ref12 = this.tanks;
      for (_p = 0, _len8 = _ref12.length; _p < _len8; _p++) {
        t = _ref12[_p];
        if (t.alive) {
          tank = t;
        }
      }
      if (tank === this.currentTank) {
        this.achieved('last alive');
      }
    }
    this.tick++;
    _ref13 = this.tanks;
    _results = [];
    for (_q = 0, _len9 = _ref13.length; _q < _len9; _q++) {
      t = _ref13[_q];
      _results.push(within(t, {
        x: 0,
        y: 0
      }, 32) ? (t === this.currentTank ? (this.achieved('win box'), this.tick <= 60 * 15 ? this.achieved('win box timelimit') : void 0) : void 0, t.team === this.currentTank.team ? (play('win'), this.achieved('win')) : play('youdie'), this.endRound(t.team)) : void 0);
    }
    return _results;
  };
  Game.prototype.achieved = function(thing) {
    if (thing !== 'last alive') {
      return console.log('done', thing);
    }
  };
  Game.prototype.draw = function() {
    var bullet, frame, secs, sprite, tank, _i, _j, _len, _len2, _ref, _ref2;
    if (this.state === 'menu') {
      return this.drawMenu();
    }
    ctx.fillStyle = 'rgb(215,232,148)';
    ctx.fillRect(-400, -300, 800, 600);
    this.drawBackground();
    _ref = this.bullets;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      bullet = _ref[_i];
      ctx.save();
      ctx.translate(bullet.x, bullet.y);
      ctx.rotate(bullet.angle + TAU / 4);
      frame = Math.floor(this.tick / 3) % 3;
      ctx.drawImage(spritesheet, 32 + 8 * frame, 96, 6, 18, -3, -9, 6, 18);
      ctx.restore();
    }
    _ref2 = this.tanks;
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      tank = _ref2[_j];
      ctx.save();
      ctx.translate(tank.x, tank.y);
      ctx.rotate(tank.angle + TAU / 4);
      if (tank === this.currentTank) {
        ctx.lineWidth = 1.5;
        if (tank.team) {
          ctx.strokeStyle = 'rgb(32,70,49)';
        } else {
          ctx.strokeStyle = 'rgb(70,76,33)';
        }
        ctx.strokeRect(-18, -18, 36, 36);
      }
      sprite = tank.team ? 0 : 1;
      if (tank.alive) {
        frame = Math.floor(tank.distance / 2) % 4;
        ctx.drawImage(spritesheet, 64 + frame * 32, 96 + sprite * 32, 32, 32, -16, -16, 32, 32);
      } else {
        ctx.drawImage(spritesheet, 64, 192 + sprite * 32, 32, 32, -16, -16, 32, 32);
      }
      ctx.restore();
    }
    ctx.save();
    ctx.scale(1, -1);
    ctx.drawImage(spritesheet, 224, 64, 64, 64, -32, -48, 64, 64);
    ctx.restore();
    ctx.scale(1, -1);
    ctx.textAlign = 'left';
    ctx.font = '20px KongtextRegular';
    ctx.fillStyle = 'rgb(32,70,49)';
    ctx.fillText('SCORE:', 50, -260, 600);
    ctx.textAlign = 'right';
    ctx.fillText("" + this.score, 280, -260, 600);
    switch (this.state) {
      case 'round over':
        ctx.textAlign = 'center';
        ctx.font = '26px KongtextRegular';
        ctx.fillStyle = 'rgb(32,70,49)';
        ctx.fillText('Mission Complete', 0, -110, 600);
        break;
      case 'round starting':
        secs = 3 - Math.floor(this.stateTick / 35);
        if (secs === 0) {
          secs = 'GO!';
        }
        ctx.textAlign = 'center';
        ctx.font = '70px KongtextRegular';
        ctx.fillStyle = 'rgb(32,70,49)';
        ctx.fillText("" + secs, 0, -110, 600);
        break;
      case 'game over':
        if ((this.stateTick % 30) < 15 || this.stateTick >= 30 * 3) {
          ctx.textAlign = 'center';
          ctx.font = '50px KongtextRegular';
          ctx.fillStyle = 'rgb(32,70,49)';
          ctx.fillText("GAME OVER", 0, -110, 600);
        }
        if (this.stateTick >= 30 * 3) {
          ctx.font = '20px KongtextRegular';
          ctx.fillText('Press space to retry', 0, 100, 600);
        }
    }
    if (!muted) {
      ctx.drawImage(spritesheet, 94 * 2, 99 * 2, 20, 20, 360, 260, 20, 20);
    } else {
      ctx.drawImage(spritesheet, 81 * 2, 99 * 2, 20, 20, 360, 260, 20, 20);
    }
    return ctx.scale(1, -1);
  };
  Game.prototype.drawBackground = function() {
    var b, _i, _len, _ref, _results;
    _ref = this.background;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      b = _ref[_i];
      _results.push(ctx.drawImage(spritesheet, (80 + 16 * b.tile) * 2, 16 * 2, 32, 32, b.x, b.y, 32, 32));
    }
    return _results;
  };
  Game.prototype.toggleMute = function() {
    var _ref, _ref2, _ref3, _ref4;
    if (!muted) {
      muted = true;
      if (mixer != null) {
        mixer.gain.value = 0;
      }
      if ((_ref = this.menuMusic) != null) {
        _ref.volume = 0;
      }
      return (_ref2 = this.gameMusic) != null ? _ref2.volume = 0 : void 0;
    } else {
      muted = false;
      if (mixer != null) {
        mixer.gain.value = 1;
      }
      if ((_ref3 = this.menuMusic) != null) {
        _ref3.volume = 1;
      }
      return (_ref4 = this.gameMusic) != null ? _ref4.volume = 1 : void 0;
    }
  };
  Game.prototype.updateMenu = function() {
    if (atom.input.pressed('click') || atom.input.pressed('shoot')) {
      if (atom.input.mouse.x > 700 && atom.input.mouse.y > 500) {
        return this.toggleMute();
      } else {
        return this.startGame();
      }
    }
  };
  Game.prototype.drawMenu = function() {
    ctx.fillStyle = 'rgb(215,232,148)';
    ctx.fillRect(-400, -300, 800, 600);
    ctx.textAlign = 'center';
    ctx.fillStyle = 'rgb(32,70,49)';
    ctx.save();
    ctx.scale(1, -1);
    ctx.font = '60px KongtextRegular';
    ctx.fillText('Tanks a lot!', 0, -80, 600);
    ctx.font = '20px KongtextRegular';
    ctx.fillText('Press space to start', 0, 20, 600);
    if (!muted) {
      ctx.drawImage(spritesheet, 94 * 2, 99 * 2, 20, 20, 360, 260, 20, 20);
    } else {
      ctx.drawImage(spritesheet, 81 * 2, 99 * 2, 20, 20, 360, 260, 20, 20);
    }
    ctx.drawImage(spritesheet, 209 * 2, 10 * 2, 179 * 2, 38 * 2, -178, 130, 179 * 2, 38 * 2);
    return ctx.restore();
  };
  return Game;
})();
atom.input.bind(atom.key.LEFT_ARROW, 'left');
atom.input.bind(atom.key.RIGHT_ARROW, 'right');
atom.input.bind(atom.key.UP_ARROW, 'up');
atom.input.bind(atom.key.DOWN_ARROW, 'down');
atom.input.bind(atom.key.SPACE, 'shoot');
atom.input.bind(atom.key.S, 'reset');
atom.input.bind(atom.button.LEFT, 'click');
doneLoading = function() {
  var game;
  game = new Game();
  return game.run();
};