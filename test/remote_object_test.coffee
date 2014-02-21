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
    t = this
    @mock_message =
      i: -1
      read: ->
        t.message[@i += 1]

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
      assert.equal(ret, 42)
      done()
    @message = [2, 0, 0, 42]
    ro.receive(@mock_message)
