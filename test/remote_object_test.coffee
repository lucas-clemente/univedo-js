univedo = require('../dist/univedo.js')

exports['remote object'] =
  setUp: (done) ->
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
    done()

  callsRom: (t) ->
    t.expect(3)
    @sentMessage = (m) ->
      t.deepEqual m, [2, 1, 0, 'foo']
    ro = new univedo.RemoteObject(@connection, 2)
    ro.callRom("foo", [])
    t.deepEqual ro.calls, [{id: 0, onreturn: undefined}]
    t.equal ro.call_id, 1
    t.done()

  romReturns: (t) ->
    t.expect(1)
    c = {stream: sendMessage: ->}
    ro = new univedo.RemoteObject(c, 2)
    ro.callRom("foo", [], (ret) -> t.equal(ret, 42))
    @message = [2, 0, 0, 42]
    ro.receive(@mock_message)
    t.done()
