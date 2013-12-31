exports.WebSocket = require("ws") unless WebSocket?

exports.Connection = class Connection
  constructor: (@url) ->
    @socket = new exports.WebSocket(@url)
    @socket.onopen = @onopen
    @socket.onmessage = @onmessage
    @socket.onerror = @onerror
    @socket.onclose = @onclose

  onopen: (e) ->
    console.log "open"

  onmessage: (e) ->
    console.log e

  onclose: (e) ->
    console.log e

  onerror: (e) ->
    console.log e
