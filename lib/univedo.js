(function() {

  (function(exports) {
    var Message, VariantMajor, VariantSimple, VariantTag, byteArrayFromArray, byteArrayFromString, byteToHex, concatArrayBufs, hexToByte, i, raw2Uuid, _i;
    byteToHex = [];
    hexToByte = {};
    for (i = _i = 0; _i <= 255; i = ++_i) {
      byteToHex[i] = (i + 0x100).toString(16).substr(1);
      hexToByte[byteToHex[i]] = i;
    }
    raw2Uuid = function(buf) {
      i = 0;
      return byteToHex[buf[i++]] + byteToHex[buf[i++]] + byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' + byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' + byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' + byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' + byteToHex[buf[i++]] + byteToHex[buf[i++]] + byteToHex[buf[i++]] + byteToHex[buf[i++]] + byteToHex[buf[i++]] + byteToHex[buf[i++]];
    };
    byteArrayFromString = function(s) {
      var buf, bufView, _j, _ref;
      buf = new ArrayBuffer(s.length);
      bufView = new Uint8Array(buf);
      for (i = _j = 0, _ref = s.length - 1; 0 <= _ref ? _j <= _ref : _j >= _ref; i = 0 <= _ref ? ++_j : --_j) {
        bufView[i] = s.charCodeAt(i);
      }
      return buf;
    };
    byteArrayFromArray = function(arr) {
      return byteArrayFromString(String.fromCharCode.apply(null, arr));
    };
    concatArrayBufs = function(buf1, buf2) {
      var tmp;
      tmp = new Uint8Array(buf1.byteLength + buf2.byteLength);
      tmp.set(new Uint8Array(buf1), 0);
      tmp.set(new Uint8Array(buf2), buf1.byteLength);
      return tmp.buffer;
    };
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
        var len, major, obj, tag, typeInt, _j, _k, _ref, _ref1, _results;
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
              case VariantSimple.FLOAT32:
                return this.getDataView(4).getFloat32(0);
              case VariantSimple.FLOAT64:
                return this.getDataView(8).getFloat64(0);
              default:
                throw "invalid simple in cbor protocol";
            }
            break;
          case VariantMajor.BYTESTRING:
            len = this.getLen(typeInt);
            return this.buffer.slice(this.offset, this.offset += len);
          case VariantMajor.TEXTSTRING:
            len = this.getLen(typeInt);
            return String.fromCharCode.apply(null, new Uint8Array(this.buffer.slice(this.offset, this.offset += len)));
          case VariantMajor.ARRAY:
            len = this.getLen(typeInt);
            _results = [];
            for (i = _j = 0, _ref = len - 1; 0 <= _ref ? _j <= _ref : _j >= _ref; i = 0 <= _ref ? ++_j : --_j) {
              _results.push(this.read());
            }
            return _results;
            break;
          case VariantMajor.MAP:
            len = this.getLen(typeInt);
            obj = {};
            for (i = _k = 0, _ref1 = len - 1; 0 <= _ref1 ? _k <= _ref1 : _k >= _ref1; i = 0 <= _ref1 ? ++_k : --_k) {
              obj[this.read()] = this.read();
            }
            return obj;
          case VariantMajor.TAG:
            tag = this.getLen(typeInt);
            switch (tag) {
              case VariantTag.TIME:
              case VariantTag.DATETIME:
                return new Date(this.read());
              case VariantTag.UUID:
                return raw2Uuid(this.read());
              default:
                throw "invalid tag in cbor protocol";
            }
            break;
          default:
            throw "invalid major in cbor protocol";
        }
      };

      Message.prototype.sendSimple = function(type) {
        return byteArrayFromArray([VariantMajor.SIMPLE << 5 | type]);
      };

      Message.prototype.sendTag = function(tag) {
        return byteArrayFromArray([VariantMajor.TAG << 5 | tag]);
      };

      Message.prototype.sendLen = function(major, len) {
        var typeInt;
        typeInt = major << 5;
        switch (false) {
          case !(len <= 23):
            return byteArrayFromArray([typeInt | len]);
          case !(len < 0x100):
            return byteArrayFromArray([typeInt | 24, len]);
          case !(len < 0x10000):
            return byteArrayFromArray([typeInt | 25, len >> 8, len & 0xff]);
          case !(len < 0x100000000):
            return byteArrayFromArray([typeInt | 26, len >> 24, len >> 16, len >> 8, len & 0xff]);
          default:
            throw "sendLen() called with non-uint";
        }
      };

      Message.prototype.sendImpl = function(obj) {
        var ba;
        switch (false) {
          case obj !== null:
            return this.sendSimple(VariantSimple.NULL);
          case obj !== true:
            return this.sendSimple(VariantSimple.TRUE);
          case obj !== false:
            return this.sendSimple(VariantSimple.FALSE);
          case typeof obj !== "number":
            switch (false) {
              case !(obj >= 0 && obj < 0x100000000 && (obj % 1 === 0)):
                return this.sendLen(VariantMajor.UINT, obj);
              case !(obj < 0 && obj >= -0x100000000 && (obj % 1 === 0)):
                return this.sendLen(VariantMajor.NEGINT, -obj - 1);
              default:
                ba = new ArrayBuffer(8);
                new DataView(ba).setFloat64(0, obj);
                return concatArrayBufs(this.sendSimple(VariantSimple.FLOAT64), ba);
            }
            break;
          default:
            throw "unsupported object in cbor protocol";
        }
      };

      return Message;

    })();
    return null;
  })(typeof exports !== "undefined" && exports !== null ? exports : this);

}).call(this);
