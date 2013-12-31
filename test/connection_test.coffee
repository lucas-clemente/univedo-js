univedo = require('../dist/univedo.js')

setUp: (done) ->
  done()

exports['connection'] =
  connectsWebsocket: (t) ->
    c = new univedo.Connection("ws://echo.websocket.org")
    c.socket.onopen = ->
      t.done()
