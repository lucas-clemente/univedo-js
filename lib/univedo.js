(function() {

  (function(exports) {
    var VariantMajor, VariantSimple, VariantTag;
    VariantMajor = {
      UINT: 0,
      NEGINT: 1,
      BYTESTRING: 2,
      TEXTSTRING: 3,
      ARRAY: 4,
      MAP: 5,
      TAG: 6,
      SIMPLE: 7
    };
    VariantTag = {
      DECIMAL: 4,
      REMOTEOBJECT: 6,
      UUID: 7,
      TIME: 8,
      DATETIME: 9,
      SQL: 10
    };
    VariantSimple = {
      FALSE: 20,
      TRUE: 21,
      NULL: 22,
      FLOAT16: 25,
      FLOAT32: 26,
      FLOAT64: 27
    };
    return exports.cbor = {
      read: function(buf) {
        var major, typeInt;
        typeInt = new DataView(buf).getUint8(0);
        major = typeInt >> 5;
        switch (major) {
          case VariantMajor.SIMPLE:
            switch (typeInt & 0x1F) {
              case VariantSimple.FALSE:
                return false;
              case VariantSimple.TRUE:
                return true;
              case VariantSimple.NULL:
                return null;
            }
        }
      }
    };
  })(typeof exports !== "undefined" && exports !== null ? exports : this);

}).call(this);
