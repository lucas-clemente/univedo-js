/**
 * univedo v0.1.0 
 * https://github.com/lucas-clemente/univedo-js
 * MIT license, (c) 2013-2014 Univedo
 */
(function(exports, WebSocket, Promise) {
  "use strict";
  var univedo = {
    "remote_classes": {}
  };

  var byteArrayFromArray, byteArrayFromString, byteToHex, concatArrayBufs, decodeUtf8, encodeUtf8, hexToByte, i, raw2Uuid, _i;

byteToHex = [];

hexToByte = {};

for (i = _i = 0; _i <= 255; i = ++_i) {
  byteToHex[i] = (i + 0x100).toString(16).substr(1);
  hexToByte[byteToHex[i]] = i;
}

raw2Uuid = function(raw) {
  var buf;
  buf = new Uint8Array(raw);
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

concatArrayBufs = function(bufs) {
  var b, pos, tmp, totalLength, _j, _k, _len, _len1;
  totalLength = 0;
  for (_j = 0, _len = bufs.length; _j < _len; _j++) {
    b = bufs[_j];
    totalLength += b.byteLength;
  }
  tmp = new Uint8Array(totalLength);
  pos = 0;
  for (_k = 0, _len1 = bufs.length; _k < _len1; _k++) {
    b = bufs[_k];
    tmp.set(new Uint8Array(b), pos);
    pos += b.byteLength;
  }
  return tmp.buffer;
};

encodeUtf8 = function(string) {
  var octets, utf8, _j, _ref;
  utf8 = unescape(encodeURIComponent(string));
  octets = new Uint8Array(utf8.length);
  for (i = _j = 0, _ref = utf8.length; 0 <= _ref ? _j < _ref : _j > _ref; i = 0 <= _ref ? ++_j : --_j) {
    octets[i] = utf8.charCodeAt(i);
  }
  return octets.buffer;
};

decodeUtf8 = function(buffer) {
  var utf8;
  utf8 = String.fromCharCode.apply(null, new Uint8Array(buffer));
  return decodeURIComponent(escape(utf8));
};

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
  RECORD: 8
};

CborSimple = {
  FALSE: 20,
  TRUE: 21,
  NULL: 22,
  FLOAT32: 26,
  FLOAT64: 27
};

univedo.Message = Message = (function() {
  function Message(recvBuffer, roCallback) {
    this.recvBuffer = recvBuffer;
    this.roCallback = roCallback;
    this.recvOffset = 0;
    this.sendBuffer = new ArrayBuffer(0);
  }

  Message.prototype._getDataView = function(len) {
    var dv;
    dv = new DataView(this.recvBuffer, this.recvOffset, len);
    this.recvOffset += len;
    return dv;
  };

  Message.prototype._getLen = function(typeInt) {
    var smallLen;
    smallLen = typeInt & 0x1F;
    switch (smallLen) {
      case 24:
        return this._getDataView(1).getUint8(0);
      case 25:
        return this._getDataView(2).getUint16(0);
      case 26:
        return this._getDataView(4).getUint32(0);
      case 27:
        throw Error("int64 not yet supported in javascript!");
        break;
      default:
        return smallLen;
    }
  };

  Message.prototype.shift = function() {
    var i, len, major, obj, tag, typeInt, _i, _j, _results;
    typeInt = this._getDataView(1).getUint8(0);
    major = typeInt >> 5;
    switch (major) {
      case CborMajor.UINT:
        return this._getLen(typeInt);
      case CborMajor.NEGINT:
        return -this._getLen(typeInt) - 1;
      case CborMajor.SIMPLE:
        switch (typeInt & 0x1F) {
          case CborSimple.FALSE:
            return false;
          case CborSimple.TRUE:
            return true;
          case CborSimple.NULL:
            return null;
          case CborSimple.FLOAT32:
            return this._getDataView(4).getFloat32(0);
          case CborSimple.FLOAT64:
            return this._getDataView(8).getFloat64(0);
          default:
            throw Error("invalid simple in cbor protocol");
        }
        break;
      case CborMajor.BYTESTRING:
        len = this._getLen(typeInt);
        return this.recvBuffer.slice(this.recvOffset, this.recvOffset += len);
      case CborMajor.TEXTSTRING:
        len = this._getLen(typeInt);
        return decodeUtf8(this.recvBuffer.slice(this.recvOffset, this.recvOffset += len));
      case CborMajor.ARRAY:
        len = this._getLen(typeInt);
        _results = [];
        for (i = _i = 0; 0 <= len ? _i < len : _i > len; i = 0 <= len ? ++_i : --_i) {
          _results.push(this.shift());
        }
        return _results;
        break;
      case CborMajor.MAP:
        len = this._getLen(typeInt);
        obj = {};
        for (i = _j = 0; 0 <= len ? _j < len : _j > len; i = 0 <= len ? ++_j : --_j) {
          obj[this.shift()] = this.shift();
        }
        return obj;
      case CborMajor.TAG:
        tag = this._getLen(typeInt);
        switch (tag) {
          case CborTag.DATETIME:
            return new Date(this.shift());
          case CborTag.TIME:
            return new Date(this.shift());
          case CborTag.UUID:
            return raw2Uuid(this.shift());
          case CborTag.RECORD:
            return this.shift();
          case CborTag.REMOTEOBJECT:
            return this.roCallback(this.shift());
          default:
            throw Error("invalid tag in cbor protocol");
        }
        break;
      default:
        throw Error("invalid major in cbor protocol");
    }
  };

  Message.prototype.send = function(obj) {
    return this.sendBuffer = concatArrayBufs([this.sendBuffer, this._sendImpl(obj)]);
  };

  Message.prototype._sendSimple = function(type) {
    return byteArrayFromArray([CborMajor.SIMPLE << 5 | type]);
  };

  Message.prototype._sendTag = function(tag) {
    return byteArrayFromArray([CborMajor.TAG << 5 | tag]);
  };

  Message.prototype._sendLen = function(major, len) {
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
        throw Error("_sendLen() called with non-uint");
    }
  };

  Message.prototype._sendImpl = function(obj) {
    var ba, bufs, key, keys, utf8, v, _i, _j, _len, _len1;
    switch (false) {
      case obj !== null:
        return this._sendSimple(CborSimple.NULL);
      case obj !== true:
        return this._sendSimple(CborSimple.TRUE);
      case obj !== false:
        return this._sendSimple(CborSimple.FALSE);
      case typeof obj !== "number":
        switch (false) {
          case !(obj >= 0 && obj < 0x100000000 && (obj % 1 === 0)):
            return this._sendLen(CborMajor.UINT, obj);
          case !(obj < 0 && obj >= -0x100000000 && (obj % 1 === 0)):
            return this._sendLen(CborMajor.NEGINT, -obj - 1);
          default:
            ba = new ArrayBuffer(8);
            new DataView(ba).setFloat64(0, obj);
            return concatArrayBufs([this._sendSimple(CborSimple.FLOAT64), ba]);
        }
        break;
      case typeof obj !== "string":
        utf8 = encodeUtf8(obj);
        return concatArrayBufs([this._sendLen(CborMajor.TEXTSTRING, utf8.byteLength), utf8]);
      case obj.constructor.name !== "ArrayBuffer":
        return concatArrayBufs([this._sendLen(CborMajor.BYTESTRING, obj.byteLength), obj]);
      case obj.constructor.name !== "Array":
        bufs = [this._sendLen(CborMajor.ARRAY, obj.length)];
        for (_i = 0, _len = obj.length; _i < _len; _i++) {
          v = obj[_i];
          bufs.push(this._sendImpl(v));
        }
        return concatArrayBufs(bufs);
      case obj.constructor.name !== "Object":
        keys = Object.keys(obj);
        bufs = [this._sendLen(CborMajor.MAP, keys.length)];
        for (_j = 0, _len1 = keys.length; _j < _len1; _j++) {
          key = keys[_j];
          bufs.push(this._sendImpl(key));
          bufs.push(this._sendImpl(obj[key]));
        }
        return concatArrayBufs(bufs);
      case obj.constructor.name !== "Date":
        return concatArrayBufs([this._sendTag(CborTag.DATETIME), this._sendImpl(obj.toISOString())]);
      default:
        throw Error("unsupported object in cbor protocol");
    }
  };

  return Message;

})();

var ROMOPS, RemoteObject;

ROMOPS = {
  CALL: 1,
  ANSWER: 2,
  NOTIFY: 3,
  DELETE: 4
};

univedo.RemoteObject = RemoteObject = (function() {
  function RemoteObject(session, id, method_names) {
    this.session = session;
    this.id = id;
    if (method_names == null) {
      method_names = [];
    }
    this.call_id = 0;
    this.calls = [];
    this.notification_listeners = [];
    this.session._remote_objects[this.id] = this;
    this._addROMs(method_names);
  }

  RemoteObject.prototype._callRom = function(name, args) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        _this.session._sendMessage([_this.id, ROMOPS.CALL, _this.call_id, name, args]);
        _this.calls[_this.call_id] = resolve;
        return _this.call_id += 1;
      };
    })(this));
  };

  RemoteObject.prototype._sendNotification = function(name, args) {
    return this.session._sendMessage([this.id, ROMOPS.NOTIFY, name, args]);
  };

  RemoteObject.prototype._receive = function(message) {
    var args, call_id, listener, name, opcode, result, status;
    opcode = message.shift();
    switch (opcode) {
      case ROMOPS.ANSWER:
        call_id = message.shift();
        status = message.shift();
        switch (status) {
          case 0:
            result = message.shift();
            this.calls[call_id](result);
            return this.calls[call_id] = null;
          case 2:
            throw Error(message.shift());
            break;
          default:
            throw Error("unknown rom answer status " + status);
        }
        break;
      case ROMOPS.NOTIFY:
        name = message.shift();
        args = message.shift();
        if (listener = this.notification_listeners[name]) {
          return listener.apply(this, args);
        } else {
          throw Error("unhandled notification " + name);
        }
        break;
      default:
        throw Error("unknown romop");
    }
  };

  RemoteObject.prototype._on = function(name, callback) {
    return this.notification_listeners[name] = callback;
  };

  RemoteObject.prototype._addROMs = function(rom_names) {
    var rom, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = rom_names.length; _i < _len; _i++) {
      rom = rom_names[_i];
      _results.push(this[rom] = (function(rom) {
        return function() {
          var args;
          args = Array.prototype.slice.call(arguments, 0);
          return this._callRom(rom, args);
        };
      })(rom));
    }
    return _results;
  };

  return RemoteObject;

})();

var Connection, Perspective, Query, Result, Statement,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Connection = (function(_super) {
  __extends(Connection, _super);

  function Connection(session, id) {
    Connection.__super__.constructor.call(this, session, id, ['ping', 'getPerspective']);
  }

  return Connection;

})(univedo.RemoteObject);

univedo.remote_classes['com.univedo.connection'] = Connection;

Perspective = (function(_super) {
  __extends(Perspective, _super);

  function Perspective(session, id) {
    Perspective.__super__.constructor.call(this, session, id, ['query']);
  }

  return Perspective;

})(univedo.RemoteObject);

univedo.remote_classes['com.univedo.perspective'] = Perspective;

Query = (function(_super) {
  __extends(Query, _super);

  function Query(session, id) {
    Query.__super__.constructor.call(this, session, id, ['prepare']);
  }

  return Query;

})(univedo.RemoteObject);

univedo.remote_classes['com.univedo.query'] = Query;

Statement = (function(_super) {
  __extends(Statement, _super);

  function Statement(session, id) {
    Statement.__super__.constructor.call(this, session, id);
  }

  Statement.prototype.execute = function(binds) {
    var args;
    args = binds ? [binds] : [];
    return this._callRom('execute', args).then(function(result) {
      return new Promise(function(resolve, reject) {
        return result._oncomplete = resolve;
      });
    });
  };

  return Statement;

})(univedo.RemoteObject);

univedo.remote_classes['com.univedo.statement'] = Statement;

Result = (function(_super) {
  __extends(Result, _super);

  function Result(session, id) {
    Result.__super__.constructor.call(this, session, id);
    this._on('setError', this._onerror);
    this.rows = [];
    this._on('appendRow', function(row) {
      return this.rows.push(row);
    });
    this._on('setComplete', function() {
      return this._oncomplete(this);
    });
    this.affected_rows = null;
    this.num_affected_rows = null;
    this._on('setAffectedRecords', function(r) {
      this.affected_rows = r;
      return this.num_affected_rows = this.affected_rows.length;
    });
    this.last_inserted_id = null;
    this._on('setRecord', function(r) {
      return this.last_inserted_id = r;
    });
  }

  Result.prototype._onerror = function(msg) {
    throw Error(msg);
  };

  Result.prototype._oncomplete = function(res) {};

  return Result;

})(univedo.RemoteObject);

univedo.remote_classes['com.univedo.result'] = Result;

var Session,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

univedo.Session = Session = (function() {
  function Session(url, opts, onopen, onclose, onerror) {
    this.onopen = onopen != null ? onopen : (function() {});
    this.onclose = onclose != null ? onclose : (function() {});
    this.onerror = onerror != null ? onerror : (function() {});
    this._onerror = __bind(this._onerror, this);
    this._receiveRo = __bind(this._receiveRo, this);
    this._onmessage = __bind(this._onmessage, this);
    this._onclose = __bind(this._onclose, this);
    this._socket = new WebSocket(url);
    this._socket.binaryType = "arraybuffer";
    this._socket.onopen = (function(_this) {
      return function() {
        _this._urologin = new univedo.RemoteObject(_this, 0, ['getSession']);
        return _this._urologin.getSession(opts).then(function(conn) {
          _this._connection = conn;
          return _this.onopen(_this);
        });
      };
    })(this);
    this._socket.onmessage = this._onmessage;
    this._socket.onerror = this._onerror;
    this._socket.onclose = this._onclose;
    this._remote_objects = {};
  }

  Session.prototype.close = function() {
    return this._socket.close();
  };

  Session.prototype.ping = function(v) {
    return this._connection.ping(v);
  };

  Session.prototype.getPerspective = function(uuid) {
    return this._connection.getPerspective(uuid);
  };

  Session.prototype._onclose = function(e) {
    return this.onclose();
  };

  Session.prototype._onmessage = function(e) {
    var msg;
    msg = new univedo.Message(new Uint8Array(e.data).buffer, this._receiveRo);
    return this._remote_objects[msg.shift()]._receive(msg);
  };

  Session.prototype._receiveRo = function(arr) {
    var id, klass, name, ro;
    id = arr[0], name = arr[1];
    klass = univedo.remote_classes[name];
    if (!klass) {
      throw Error("unknown remote object class " + name);
    }
    return ro = new klass(this, id);
  };

  Session.prototype._onerror = function(e) {
    console.error("error " + e);
    return this.onerror();
  };

  Session.prototype._sendMessage = function(m) {
    var msg, v, _i, _len;
    msg = new univedo.Message();
    for (_i = 0, _len = m.length; _i < _len; _i++) {
      v = m[_i];
      msg.send(v);
    }
    return this._socket.send(msg.sendBuffer);
  };

  return Session;

})();


  exports.univedo = univedo;
})(
  typeof exports !== "undefined" && exports !== null ? exports : this,
  typeof WebSocket !== "undefined" && WebSocket !== null ? WebSocket : require("ws"),
  typeof Promise !== "undefined" && Promise !== null ? Promise : require("es6-promise").Promise
);
