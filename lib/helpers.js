var byteArrayFromArray, byteArrayFromString, byteToHex, concatArrayBufs, hexToByte, i, raw2Uuid, _i;

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
