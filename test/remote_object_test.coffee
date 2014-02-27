univedo = require('../dist/univedo.js').univedo
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
    assert.equal ro.call_id, 1
    assert.deepEqual @sent_messages, [[2, 1, 0, 'foo', [1, 2, 3]]]

  it 'calls added roms', ->
    ro = new univedo.RemoteObject(@session, 2)
    ro._addROMs ['foo']
    ro.foo(1, 2, 3)
    assert.deepEqual @sent_messages, [[2, 1, 0, 'foo', [1, 2, 3]]]

  it 'sends notifications', ->
    ro = new univedo.RemoteObject(@session, 2)
    ro._sendNotification("foo", [1, 2, 3])
    assert.deepEqual @sent_messages, [[2, 3, 'foo', [1, 2, 3]]]

  it 'returns from roms', (done) ->
    ro = new univedo.RemoteObject(@session, 2)
    ro._callRom "foo", []
      .then (ret) ->
        assert.deepEqual(ret, 42)
        done()
    ro._receive([2, 0, 0, 42])

  it 'returns errors from roms', (done) ->
    ro = new univedo.RemoteObject(@session, 2)
    ro._callRom "foo", []
      .catch (err) ->
        assert.deepEqual("catastrophic error", err)
        done()
    ro._receive([2, 0, 2, "catastrophic error"])

  it 'receives notifications', (done) ->
    ro = new univedo.RemoteObject(@session, 2)
    ro._on 'foo', ->
      done()
    ro._receive([3, 'foo', [42]])
