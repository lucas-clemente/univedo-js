ROMOPS =
  CALL: 1
  ANSWER: 2
  NOTIFY: 3
  DELETE: 4

univedo.RemoteObject = class RemoteObject
  constructor: (@session, @id) ->
    @call_id = 0
    @calls = []
    @notification_listeners = []
    @session._remote_objects[@id] = this

  _callRom: (name, args, onreturn) ->
    @session._sendMessage([@id, ROMOPS.CALL, @call_id, name, args])
    call =
      id: @call_id
      onreturn: onreturn
    @calls.push(call)
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
            call = @calls.splice(call_id, 1)[0]
            call.onreturn(result)
          when 2
            # TODO proper error handling
            throw Error message.shift()
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

  on: (name, callback) ->
    @notification_listeners[name] = callback
