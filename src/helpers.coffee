# UUID conversion raw <=> string
byteToHex = []
hexToByte = {}
for i in [0..255]
  byteToHex[i] = (i + 0x100).toString(16).substr(1)
  hexToByte[byteToHex[i]] = i

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

concatArrayBufs = (bufs) ->
  totalLength = 0
  totalLength += b.byteLength for b in bufs
  tmp = new Uint8Array(totalLength)
  pos = 0
  for b in bufs
    tmp.set(new Uint8Array(b), pos)
    pos += b.byteLength
  tmp.buffer
