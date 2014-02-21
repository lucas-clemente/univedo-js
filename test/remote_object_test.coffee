requirejs = require 'requirejs'
requirejs.config
  nodeRequire: require

univedo = requirejs('dist/univedo.js')
assert = require 'assert'

describe 'remote object', ->
  beforeEach ->
    @sentMessage = ->
    @connection =
      stream:
        sendMessage: (m) =>
          @sentMessage(m)

  it 'calls roms', ->
    @sentMessage = (m) ->
      assert.deepEqual m, [2, 1, 0, 'foo']
    ro = new univedo.RemoteObject(@connection, 2)
    ro.callRom("foo", [])
    assert.deepEqual ro.calls, [{id: 0, onreturn: undefined}]
    assert.equal ro.call_id, 1

  it 'returns from roms', (done) ->
    c = {stream: sendMessage: ->}
    ro = new univedo.RemoteObject(c, 2)
    ro.callRom "foo", [], (ret) ->
      assert.deepEqual(ret, 42)
      done()
    ro.receive([2, 0, 0, 42])

  it 'receives notifications', (done) ->
    c = {stream: sendMessage: ->}
    ro = new univedo.RemoteObject(c, 2)
    ro.on 'foo', ->
      done()
    ro.receive([3, 'foo', [42]])
