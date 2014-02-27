(function(exports, WebSocket, Promise) {
  "use strict";
  var univedo = {
    "remote_classes": {}
  };

  <%= contents %>

  exports.univedo = univedo;
})(
  typeof exports !== "undefined" && exports !== null ? exports : this,
  typeof WebSocket !== "undefined" && WebSocket !== null ? WebSocket : require("ws"),
  typeof Promise !== "undefined" && Promise !== null ? Promise : require("es6-promise").Promise
);
