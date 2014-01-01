var Connection;

if (typeof WebSocket === "undefined" || WebSocket === null) {
  exports.WebSocket = require("ws");
}

exports.Connection = Connection = (function() {
  function Connection(url) {
    this.url = url;
    this.socket = new exports.WebSocket(this.url);
    this.socket.onopen = this.onopen;
    this.socket.onmessage = this.onmessage;
    this.socket.onerror = this.onerror;
    this.socket.onclose = this.onclose;
  }

  Connection.prototype.close = function() {
    return this.socket.close();
  };

  Connection.prototype.onopen = function(e) {
    return console.log("open");
  };

  Connection.prototype.onmessage = function(e) {
    return console.log("message");
  };

  Connection.prototype.onclose = function(e) {
    return console.log("close");
  };

  Connection.prototype.onerror = function(e) {
    return console.log("error");
  };

  return Connection;

})();
