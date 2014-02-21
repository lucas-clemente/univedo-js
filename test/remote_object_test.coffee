requirejs = require 'requirejs'
requirejs.config
  nodeRequire: require

univedo = requirejs('dist/univedo.js')
assert = require 'assert'

describe 'remote object', ->
  beforeEach ->
    @sent_messages = []
    @connection =
      stream:
        sendMessage: (m) =>
          @sent_messages.push(m)

  it 'calls roms', ->
    ro = new univedo.RemoteObject(@connection, 2)
    ro.callRom("foo", [1, 2, 3])
    assert.deepEqual ro.calls, [{id: 0, onreturn: undefined}]
    assert.equal ro.call_id, 1
    assert.deepEqual @sent_messages, [[2, 1, 0, 'foo', [1, 2, 3]]]

  it 'sends notifications', ->
    ro = new univedo.RemoteObject(@connection, 2)
    ro.sendNotification("foo", [1, 2, 3])
    assert.deepEqual @sent_messages, [[2, 3, 'foo', [1, 2, 3]]]

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
