ROMOPS =
  CALL: 1
  ANSWER: 2
  NOTIFY: 3
  DELETE: 4

exports.RemoteObject = class RemoteObject
  constructor: (@connection, @id) ->
    @call_id = 0
    @calls = []
    @notification_listeners = []

  callRom: (name, args, onreturn) ->
    @connection.stream.sendMessage([
      @id, ROMOPS.CALL, @call_id, name
    ].concat(args))
    call =
      id: @call_id
      onreturn: onreturn
    @calls.push(call)
    @call_id += 1

  receive: (message) ->
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
