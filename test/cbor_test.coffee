univedo = require('../dist/univedo.js')

String.prototype.b = ->
  buf = new ArrayBuffer(@length)
  bufView = new Uint8Array(buf)
  for i in [0..@length-1]
    bufView[i] = @charCodeAt(i)
  buf

setUp: (done) ->
  done()

exports['cbor'] =

  readsSimple: (t) ->
    t.equal new univedo.Message("\xf6".b()).read(), null, 'reads null'
    t.equal new univedo.Message("\xf5".b()).read(), true, 'reads true'
    t.equal new univedo.Message("\xf4".b()).read(), false, 'reads false'
    t.done()

  readsIntegers: (t) ->
    t.equal new univedo.Message("\x18\x2a".b()).read(), 42, 'reads uint'
    t.equal new univedo.Message("\x18\x64".b()).read(), 100, 'reads uint'
    t.equal new univedo.Message("\x1a\x00\x0f\x42\x40".b()).read(), 1000000, 'reads uint'
    t.equal new univedo.Message("\x20".b()).read(), -1, 'reads nint'
    t.equal new univedo.Message("\x38\x63".b()).read(), -100, 'reads nint'
    t.equal new univedo.Message("\x39\x03\xe7".b()).read(), -1000, 'reads nint'
    t.done()

  readsFloats: (t) ->
    t.equal new univedo.Message("\xfa\x47\xc3\x50\x00".b()).read(), 100000.0, 'reads floats'
    t.equal new univedo.Message("\xfb\x3f\xf1\x99\x99\x99\x99\x99\x9a".b()).read(), 1.1, 'reads floats'
    t.done()

  readsStrings: (t) ->
    t.deepEqual new univedo.Message("\x46foobar".b()).read(), "foobar".b(), 'reads blobs'
    t.equal new univedo.Message("\x66foobar".b()).read(), "foobar", 'reads strings'
    # t.deepEqual new univedo.Message("\x66f\xc3\xb6obar".b()).read(), "föobar", 'reads utf8strings'
    t.done()

  readsCollections: (t) ->
    t.deepEqual new univedo.Message("\x82\x63foo\x63bar".b()).read(), ["foo", "bar"], 'reads arrays'
    t.deepEqual new univedo.Message("\xa2\x63bar\x02\x63foo\x01".b()).read(), {foo: 1, bar: 2}, 'reads maps'
    t.done()

  readsTimes: (t) ->
    t.deepEqual new univedo.Message("\xc0\x74\x32\x30\x31\x33\x2d\x30\x33\x2d\x32\x31\x54\x32\x30\x3a\x30\x34\x3a\x30\x30\x5a".b()).read(), new Date("2013-03-21T20:04:00Z"), 'reads datetimes'
    t.deepEqual new univedo.Message("\xc1\x1a\x51\x4b\x67\xb0".b()).read(), new Date(1363896240), 'reads times'
    t.done()

  readsUuids: (t) ->
    t.equal new univedo.Message("\xc7\x50\x68\x4E\xF8\x95\x72\xA2\x42\x98\xBC\x5B\x58\x0F\x1C\x1D\x27\x07".b()).read(), "684ef895-72a2-4298-bc5b-580f1c1d2707", 'reads uuids'
    t.done()

  sendsSimple: (t) ->
    t.deepEqual new univedo.Message().sendImpl(null), "\xf6".b(), 'sends null'
    t.deepEqual new univedo.Message().sendImpl(true), "\xf5".b(), 'sends true'
    t.deepEqual new univedo.Message().sendImpl(false), "\xf4".b(), 'sends false'
    t.done()

  sendsIntegers: (t) ->
    t.deepEqual new univedo.Message().sendImpl(1), "\x01".b(), 'sends uint'
    t.deepEqual new univedo.Message().sendImpl(42), "\x18\x2a".b(), 'sends uint'
    t.deepEqual new univedo.Message().sendImpl(100), "\x18\x64".b(), 'sends uint'
    t.deepEqual new univedo.Message().sendImpl(1000000), "\x1a\x00\x0f\x42\x40".b(), 'sends uint'
    t.deepEqual new univedo.Message().sendImpl(-1), "\x20".b(), 'sends nint'
    t.deepEqual new univedo.Message().sendImpl(-100), "\x38\x63".b(), 'sends nint'
    t.deepEqual new univedo.Message().sendImpl(-1000), "\x39\x03\xe7".b(), 'sends nint'
    t.done()

  sendsFloats: (t) ->
    t.deepEqual new univedo.Message().sendImpl(1.1), "\xfb\x3f\xf1\x99\x99\x99\x99\x99\x9a".b(), 'sends float32'
    t.deepEqual new univedo.Message().sendImpl(1.0e+300), "\xfb\x7e\x37\xe4\x3c\x88\x00\x75\x9c".b(), 'sends float64'
    t.done()

  sendsStrings: (t) ->
    t.deepEqual new univedo.Message().sendImpl("foobar".b()), "\x46foobar".b(), 'sends blobs'
    t.deepEqual new univedo.Message().sendImpl("foobar"), "\x66foobar".b(), 'sends strings'
    # t.deepEqual new univedo.Message().sendImpl("föobar"), "\x66f\xc3\xb6obar".b(), 'sends utf8strings'
    t.done()

  sendsCollections: (t) ->
    t.deepEqual new univedo.Message().sendImpl(["foo", "bar"]), "\x82\x63foo\x63bar".b(), 'sends arrays'
    # The exact order of keys in an object is undefined, but this does the job as of node v0.10.24
    t.deepEqual new univedo.Message().sendImpl({foo: 1, bar: 2}), "\xa2\x63foo\x01\x63bar\x02".b(), 'sends maps'
    t.done()

  sendsTimes: (t) ->
    t.deepEqual new univedo.Message().sendImpl(new Date("2013-03-21T20:04:00Z")), "\xc0\x78\x18\x32\x30\x31\x33\x2d\x30\x33\x2d\x32\x31\x54\x32\x30\x3a\x30\x34\x3a\x30\x30.000\x5a".b(), 'sends datetimes'
    t.done()

  sendsMultiple: (t) ->
    m = new univedo.Message()
    m.send("foobar")
    m.send(42)
    t.deepEqual m.sendBuffer, "\x66foobar\x18\x2a".b(), "sends multiple values"
    t.done()
