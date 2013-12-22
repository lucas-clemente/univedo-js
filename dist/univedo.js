(function() {

  (function(exports) {
    return exports.awesome = function() {
      return 'awesome';
    };
  })(typeof exports !== "undefined" && exports !== null ? exports : this);

}).call(this);
