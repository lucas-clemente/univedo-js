exports.WebSocket = require("ws") unless WebSocket?

exports.Connection = class Connection
  constructor: (@url) ->
    @socket = new exports.WebSocket(@url)
    @socket.onopen = @onopen
    @socket.onmessage = @onmessage
    @socket.onerror = @onerror
    @socket.onclose = @onclose

  close: ->
    @socket.close()

  onopen: (e) ->
    console.log "open"

  onmessage: (e) ->
    console.log "message"

  onclose: (e) ->
    console.log "close"

  onerror: (e) ->
    console.log "error"
