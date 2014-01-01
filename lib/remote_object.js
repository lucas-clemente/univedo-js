var ROMOPS, RemoteObject;

ROMOPS = {
  CALL: 1,
  ANSWER: 2,
  NOTIFY: 3,
  DELETE: 4
};

exports.RemoteObject = RemoteObject = (function() {
  function RemoteObject(connection, id) {
    this.connection = connection;
    this.id = id;
    this.call_id = 0;
    this.calls = [];
  }

  RemoteObject.prototype.callRom = function(name, args, onreturn) {
    var call;
    this.connection.stream.sendMessage([this.id, ROMOPS.CALL, this.call_id, name].concat(args));
    call = {
      id: this.call_id,
      onreturn: onreturn
    };
    this.calls.push(call);
    return this.call_id += 1;
  };

  RemoteObject.prototype.receive = function(message) {
    var call_id, callback, opcode, result, status;
    opcode = message.read();
    switch (opcode) {
      case ROMOPS.ANSWER:
        call_id = message.read();
        status = message.read();
        switch (status) {
          case 0:
            result = message.read();
            callback = this.calls[call_id].onreturn;
            this.calls.splice(call_id, 1);
            return callback(result);
        }
        break;
      default:
        throw "unknown romop";
    }
  };

  return RemoteObject;

})();
