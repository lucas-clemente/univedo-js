exports.Connection = class Connection
  constructor: (@url) ->
    @socket = new ws(@url)
    @socket.onopen = @_onopen
    @socket.onmessage = @_onmessage
    @socket.onerror = @_onerror
    @socket.onclose = @_onclose

  close: ->
    @socket.close()

  _onopen: (e) =>
    @onopen()

  _onclose: (e) =>
    @onclose()


  _onmessage: (e) ->
    console.log "message"

  _onerror: (e) ->
    console.log "error"

  onopen: ->
  onclose: ->
