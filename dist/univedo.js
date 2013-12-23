(function() {

  (function(exports) {
    var Message, VariantMajor, VariantSimple, VariantTag;
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
    exports.Message = Message = (function() {

      function Message(buffer) {
        this.buffer = buffer;
        this.offset = 0;
      }

      Message.prototype.getDataView = function(len) {
        var dv;
        dv = new DataView(this.buffer, this.offset, len);
        this.offset += len;
        return dv;
      };

      Message.prototype.getLen = function(typeInt) {
        var smallLen;
        smallLen = typeInt & 0x1F;
        switch (smallLen) {
          case 24:
            return this.getDataView(1).getUint8(0);
          case 25:
            return this.getDataView(2).getUint16(0);
          case 26:
            return this.getDataView(4).getUint32(0);
          case 27:
            throw "int64 not yet supported in javascript!";
            break;
          default:
            return smallLen;
        }
      };

      Message.prototype.read = function() {
        var major, typeInt;
        typeInt = this.getDataView(1).getUint8(0);
        major = typeInt >> 5;
        switch (major) {
          case VariantMajor.UINT:
            return this.getLen(typeInt);
          case VariantMajor.NEGINT:
            return -this.getLen(typeInt) - 1;
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
      };

      return Message;

    })();
    return null;
  })(typeof exports !== "undefined" && exports !== null ? exports : this);

}).call(this);
