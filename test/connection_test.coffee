requirejs = require 'requirejs'
requirejs.config
  nodeRequire: require

univedo = requirejs('dist/univedo.js')
assert = require 'assert'

describe 'Connection', ->
  it 'connects to univedo', (done) ->
    c = new univedo.Connection("ws://localhost:9011")
    c.socket.onopen = (e) ->
      c.onopen(e)
      c.close()
    c.socket.onclose = (e) ->
      c.onclose(e)
      done()
