var CborMajor, CborSimple, CborTag, Message;

CborMajor = {
  UINT: 0,
  NEGINT: 1,
  BYTESTRING: 2,
  TEXTSTRING: 3,
  ARRAY: 4,
  MAP: 5,
  TAG: 6,
  SIMPLE: 7
};

CborTag = {
  DATETIME: 0,
  TIME: 1,
  DECIMAL: 4,
  REMOTEOBJECT: 6,
  UUID: 7,
  SQL: 10
};

CborSimple = {
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
    var i, len, major, obj, tag, typeInt, _i, _j, _ref, _ref1, _results;
    typeInt = this.getDataView(1).getUint8(0);
    major = typeInt >> 5;
    switch (major) {
      case CborMajor.UINT:
        return this.getLen(typeInt);
      case CborMajor.NEGINT:
        return -this.getLen(typeInt) - 1;
      case CborMajor.SIMPLE:
        switch (typeInt & 0x1F) {
          case CborSimple.FALSE:
            return false;
          case CborSimple.TRUE:
            return true;
          case CborSimple.NULL:
            return null;
          case CborSimple.FLOAT32:
            return this.getDataView(4).getFloat32(0);
          case CborSimple.FLOAT64:
            return this.getDataView(8).getFloat64(0);
          default:
            throw "invalid simple in cbor protocol";
        }
        break;
      case CborMajor.BYTESTRING:
        len = this.getLen(typeInt);
        return this.buffer.slice(this.offset, this.offset += len);
      case CborMajor.TEXTSTRING:
        len = this.getLen(typeInt);
        return String.fromCharCode.apply(null, new Uint8Array(this.buffer.slice(this.offset, this.offset += len)));
      case CborMajor.ARRAY:
        len = this.getLen(typeInt);
        _results = [];
        for (i = _i = 0, _ref = len - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
          _results.push(this.read());
        }
        return _results;
        break;
      case CborMajor.MAP:
        len = this.getLen(typeInt);
        obj = {};
        for (i = _j = 0, _ref1 = len - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
          obj[this.read()] = this.read();
        }
        return obj;
      case CborMajor.TAG:
        tag = this.getLen(typeInt);
        switch (tag) {
          case CborTag.DATETIME:
            return new Date(this.read());
          case CborTag.TIME:
            return new Date(this.read());
          case CborTag.UUID:
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
    return byteArrayFromArray([CborMajor.SIMPLE << 5 | type]);
  };

  Message.prototype.sendTag = function(tag) {
    return byteArrayFromArray([CborMajor.TAG << 5 | tag]);
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
    var ba, bufs, key, keys, v, _i, _j, _len, _len1;
    switch (false) {
      case obj !== null:
        return this.sendSimple(CborSimple.NULL);
      case obj !== true:
        return this.sendSimple(CborSimple.TRUE);
      case obj !== false:
        return this.sendSimple(CborSimple.FALSE);
      case typeof obj !== "number":
        switch (false) {
          case !(obj >= 0 && obj < 0x100000000 && (obj % 1 === 0)):
            return this.sendLen(CborMajor.UINT, obj);
          case !(obj < 0 && obj >= -0x100000000 && (obj % 1 === 0)):
            return this.sendLen(CborMajor.NEGINT, -obj - 1);
          default:
            ba = new ArrayBuffer(8);
            new DataView(ba).setFloat64(0, obj);
            return concatArrayBufs([this.sendSimple(CborSimple.FLOAT64), ba]);
        }
        break;
      case typeof obj !== "string":
        return concatArrayBufs([this.sendLen(CborMajor.TEXTSTRING, obj.length), byteArrayFromString(obj)]);
      case obj.constructor.name !== "ArrayBuffer":
        return concatArrayBufs([this.sendLen(CborMajor.BYTESTRING, obj.byteLength), obj]);
      case obj.constructor.name !== "Array":
        bufs = [this.sendLen(CborMajor.ARRAY, obj.length)];
        for (_i = 0, _len = obj.length; _i < _len; _i++) {
          v = obj[_i];
          bufs.push(this.sendImpl(v));
        }
        return concatArrayBufs(bufs);
      case obj.constructor.name !== "Object":
        keys = Object.keys(obj);
        bufs = [this.sendLen(CborMajor.MAP, keys.length)];
        for (_j = 0, _len1 = keys.length; _j < _len1; _j++) {
          key = keys[_j];
          bufs.push(this.sendImpl(key));
          bufs.push(this.sendImpl(obj[key]));
        }
        return concatArrayBufs(bufs);
      case obj.constructor.name !== "Date":
        return concatArrayBufs([this.sendTag(CborTag.DATETIME), this.sendImpl(obj.toISOString())]);
      default:
        throw "unsupported object in cbor protocol";
    }
  };

  return Message;

})();
