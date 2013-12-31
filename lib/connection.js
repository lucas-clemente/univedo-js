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

  Connection.prototype.onopen = function(e) {
    return console.log("open");
  };

  Connection.prototype.onmessage = function(e) {
    return console.log(e);
  };

  Connection.prototype.onclose = function(e) {
    return console.log(e);
  };

  Connection.prototype.onerror = function(e) {
    return console.log(e);
  };

  return Connection;

})();
