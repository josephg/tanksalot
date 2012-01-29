# This is a trivial http server, because the game doesn't work properly from a file:/// link.
# This requires nodejs and connect.
#
# % npm install connect
# % node server.js

connect = require 'connect'

connect.createServer(
    connect.favicon()
#  , connect.logger()
  , connect.static(__dirname + '/')
).listen(8000)

console.log 'Listening on http://localhost:8000/'

