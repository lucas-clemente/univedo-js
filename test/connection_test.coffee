univedo = require('../dist/univedo.js')

exports['connection'] =
  connectsWebsocket: (t) ->
    t.expect(2)
    c = new univedo.Connection("ws://localhost:9011")
    c.socket.onopen = (e) ->
      c.onopen(e)
      c.close()
      t.ok(true)
    c.socket.onclose = (e) ->
      c.onclose(e)
      t.ok(true)
      t.done()
