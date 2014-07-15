ROMOPS =
  CALL: 1
  ANSWER: 2
  NOTIFY: 3
  DELETE: 4

univedo.RemoteObject = class RemoteObject
  constructor: (@session, @id, method_names = []) ->
    @call_id = 0
    @calls = []
    @notification_listeners = {}
    @session._remote_objects[@id] = this
    @_addROMs method_names

  _callRom: (name, args) ->
    new Promise (resolve, reject) =>
      @session._sendMessage([@id, ROMOPS.CALL, @call_id, name, args])
      @calls[@call_id] =
        success: resolve
        fail: reject
      @call_id += 1

  _sendNotification: (name, args) ->
    @session._sendMessage([@id, ROMOPS.NOTIFY, name, args])

  _receive: (message) ->
    opcode = message.shift()
    switch opcode
      when ROMOPS.ANSWER
        call_id = message.shift()
        status = message.shift()
        switch status
          when 0
            result = message.shift()
            @calls[call_id].success(result)
            @calls[call_id] = null
          when 1
            @calls[call_id].fail(message.shift())
          else
            throw Error "unknown rom answer status " + status
      when ROMOPS.NOTIFY
        name = message.shift()
        args = message.shift()
        if listener = @notification_listeners[name]
          listener.apply(this, args)
        else
          throw Error "unhandled notification " + name
      else throw Error "unknown romop"

  _on: (name, callback) ->
    @notification_listeners[name] = callback

  _addROMs: (rom_names) ->
    for rom in rom_names
      this[rom] = ((rom) ->
        ->
          args = Array.prototype.slice.call(arguments, 0)
          @_callRom rom, args
      )(rom)
