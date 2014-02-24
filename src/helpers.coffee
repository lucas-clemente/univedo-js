# Used in UUID conversion raw <=> string
byteToHex = []
hexToByte = {}
for i in [0..255]
  byteToHex[i] = (i + 0x100).toString(16).substr(1)
  hexToByte[byteToHex[i]] = i

# ArrayBuffer raw uuid -> UUID as string
raw2Uuid = (buf) ->
  i = 0
  byteToHex[buf[i++]] + byteToHex[buf[i++]] +
  byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' +
  byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' +
  byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' +
  byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' +
  byteToHex[buf[i++]] + byteToHex[buf[i++]] +
  byteToHex[buf[i++]] + byteToHex[buf[i++]] +
  byteToHex[buf[i++]] + byteToHex[buf[i++]]

# Create a ByteArray from a String
byteArrayFromString = (s) ->
  buf = new ArrayBuffer(s.length)
  bufView = new Uint8Array(buf)
  for i in [0..s.length-1]
    bufView[i] = s.charCodeAt(i)
  buf

# Create a ByteArray from an array of bytes (as number)
byteArrayFromArray = (arr) ->
  byteArrayFromString(String.fromCharCode.apply(null, arr))

# Concatenate any number of ArrayBuffers
concatArrayBufs = (bufs) ->
  totalLength = 0
  totalLength += b.byteLength for b in bufs
  tmp = new Uint8Array(totalLength)
  pos = 0
  for b in bufs
    tmp.set(new Uint8Array(b), pos)
    pos += b.byteLength
  tmp.buffer

# Taken from
# http://ecmanaut.blogspot.com/2006/07/encoding-decoding-utf8-in-javascript.html

encodeUtf8 = (string) ->
  utf8 = unescape(encodeURIComponent(string))
  octets = new Uint8Array(utf8.length)
  for i in [0...utf8.length]
    octets[i] = utf8.charCodeAt(i)
  octets.buffer

decodeUtf8 = (buffer) ->
  utf8 = String.fromCharCode.apply(null, new Uint8Array(buffer))
  decodeURIComponent(escape(utf8))
