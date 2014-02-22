univedo.Session = class Session
  constructor: (url, args, @onopen = (->), @onclose = (->), @onerror = (->)) ->
    @_socket = new ws(url)
    @_socket.onopen = =>
      @urologin = new univedo.RemoteObject(this, 0)
      @urologin._callRom 'getSession', [args], (s) =>
        @session = s
        @onopen()
    @_socket.onmessage = @_onmessage
    @_socket.onerror = @_onerror
    @_socket.onclose = @_onclose
    @_remote_objects = {}

  close: ->
    @_socket.close()

  ping: (v, onreturn) ->
    @session._callRom('ping', [v], onreturn)

  _onclose: (e) =>
    @onclose()

  _onmessage: (e) =>
    # This is unneccessary in the browser. However node's ws returns a Buffer
    # instead of an ArrayBuffer, which is normalized to an ArrayBuffer here.
    msg = new univedo.Message(new Uint8Array(e.data).buffer, @_receiveRo)
    @_remote_objects[msg.shift()]._receive(msg)

  _receiveRo: (arr) =>
    id = arr[0]
    ro = new univedo.RemoteObject(this, id)
    @_remote_objects[id] = ro

  _onerror: (e) ->
    console.log "error"

  _sendMessage: (m) ->
    msg = new univedo.Message()
    msg.send v for v in m
    @_socket.send(msg.sendBuffer)
