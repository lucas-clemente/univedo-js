requirejs = require 'requirejs'
requirejs.config
  nodeRequire: require

univedo = requirejs('dist/univedo.js')
assert = require 'assert'

URL = "ws://localhost:9000/f8018f09-fb75-4d3d-8e11-44b2dc796130"
ARGS =
  9744: "marvin"

describe 'Session', ->
  beforeEach (done) ->
    @session = new univedo.Session URL, ARGS, done

  afterEach ->
    @session.close() if @session._socket.readyState == 1

  it 'connects to univedo', (done) ->
    @session.close()
    @session.onclose = done

  it 'pings bools', (done) ->
    @session.ping true, (r) ->
      assert.equal true, r
      done()
      
  it 'pings ints', (done) ->
    @session.ping 42, (r) ->
      assert.equal 42, r
      done()
