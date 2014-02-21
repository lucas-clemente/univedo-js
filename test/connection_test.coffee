requirejs = require 'requirejs'
requirejs.config
  nodeRequire: require

univedo = requirejs('dist/univedo.js')
assert = require 'assert'

describe 'Connection', ->
  it 'connects to univedo', (done) ->
    c = new univedo.Connection("ws://localhost:9011")
    c.onopen = ->
      c.close()
    c.onclose = done
    c.onerror = done

  it 'pings', (done) ->
    done()
