univedo = require('../dist/univedo.js').univedo
assert = require 'assert'

URL = "ws://vagrant/f8018f09-fb75-4d3d-8e11-44b2dc796130"
OPTS =
  username: "marvin"

describe 'Session', ->
  beforeEach (done) ->
    @session = new univedo.Session URL, OPTS, ->
      done()

  afterEach ->
    @session.close() if @session._socket.readyState == 1

  it 'connects to univedo', (done) ->
    @session.close()
    @session.onclose = done

  pingTest = (name, value) ->
    it 'pings ' + name, (done) ->
      @session.ping value
      .then (r) ->
        assert.deepEqual value, r
        done()

  pingTest 'null', null
  pingTest 'true', true
  pingTest 'false', false
  pingTest 'ints', 42
  pingTest 'negative ints', -42
  pingTest 'floats', 1.1
  pingTest 'strings', "foobar"
  pingTest 'arrays', [1, 2, 3]
  pingTest 'maps', {a: 1, b: 2}
  pingTest 'times', new Date(1363896240)

  it 'gets perspectives', (done) ->
    @session.getPerspective '6e5a3a08-9bb0-4d92-ad04-7c6fed3874fa'
    .then (p) ->
      assert.equal p.constructor.name, "Perspective"
      done()
