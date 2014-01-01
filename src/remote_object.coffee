ROMOPS =
  CALL: 1
  ANSWER: 2
  NOTIFY: 3
  DELETE: 4

exports.RemoteObject = class RemoteObject
  constructor: (@connection, @id) ->
    @call_id = 0
    @calls = []

  callRom: (name, args, onreturn) ->
    @connection.stream.sendMessage([@id, ROMOPS.CALL, @call_id, name].concat(args))
    call =
      id: @call_id
      onreturn: onreturn
    @calls.push(call)
    @call_id += 1

  receive: (message) ->
    opcode = message.read()
    switch opcode
      when ROMOPS.ANSWER
        call_id = message.read()
        status = message.read()
        switch status
          when 0
            result = message.read()
            callback = @calls[call_id].onreturn
            @calls.splice(call_id, 1)
            callback(result)
      else throw "unknown romop"
