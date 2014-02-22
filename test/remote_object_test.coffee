requirejs = require 'requirejs'
requirejs.config
  nodeRequire: require

univedo = requirejs('dist/univedo.js')
assert = require 'assert'

describe 'remote object', ->
  beforeEach ->
    @sent_messages = []
    @session =
      _remote_objects: {}
      _sendMessage: (m) =>
        @sent_messages.push(m)

  it 'registers in session', ->
    ro = new univedo.RemoteObject(@session, 2)
    assert.deepEqual @session._remote_objects, {2: ro}

  it 'calls roms', ->
    ro = new univedo.RemoteObject(@session, 2)
    ro._callRom("foo", [1, 2, 3])
    assert.deepEqual ro.calls, [{id: 0, onreturn: undefined}]
    assert.equal ro.call_id, 1
    assert.deepEqual @sent_messages, [[2, 1, 0, 'foo', [1, 2, 3]]]

  it 'sends notifications', ->
    ro = new univedo.RemoteObject(@session, 2)
    ro._sendNotification("foo", [1, 2, 3])
    assert.deepEqual @sent_messages, [[2, 3, 'foo', [1, 2, 3]]]

  it 'returns from roms', (done) ->
    ro = new univedo.RemoteObject(@session, 2)
    ro._callRom "foo", [], (ret) ->
      assert.deepEqual(ret, 42)
      done()
    ro._receive([2, 0, 0, 42])

  it 'receives notifications', (done) ->
    ro = new univedo.RemoteObject(@session, 2)
    ro.on 'foo', ->
      done()
    ro._receive([3, 'foo', [42]])
