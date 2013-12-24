univedo = require('../lib/univedo.js')

String.prototype.b = ->
  buf = new ArrayBuffer(@length)
  bufView = new Uint8Array(buf)
  for i in [0..@length-1]
    bufView[i] = @charCodeAt(i)
  buf

setUp: (done) ->
  done()

exports['cbor'] =

  readsSimple: (test) ->
    test.equal new univedo.Message("\xf6".b()).read(), null, 'reads null'
    test.equal new univedo.Message("\xf5".b()).read(), true, 'reads true'
    test.equal new univedo.Message("\xf4".b()).read(), false, 'reads false'
    test.done()

  readsIntegers: (test) ->
    test.equal new univedo.Message("\x18\x2a".b()).read(), 42, 'reads uint'
    test.equal new univedo.Message("\x18\x64".b()).read(), 100, 'reads uint'
    test.equal new univedo.Message("\x1a\x00\x0f\x42\x40".b()).read(), 1000000, 'reads uint'
    test.equal new univedo.Message("\x20".b()).read(), -1, 'reads nint'
    test.equal new univedo.Message("\x38\x63".b()).read(), -100, 'reads nint'
    test.equal new univedo.Message("\x39\x03\xe7".b()).read(), -1000, 'reads nint'
    test.done()

  readsFloats: (test) ->
    test.equal new univedo.Message("\xfa\x47\xc3\x50\x00".b()).read(), 100000.0, 'reads floats'
    test.equal new univedo.Message("\xfb\x3f\xf1\x99\x99\x99\x99\x99\x9a".b()).read(), 1.1, 'reads floats'
    test.done()

  readsStrings: (test) ->
    test.deepEqual new univedo.Message("\x46foobar".b()).read(), "foobar".b(), 'reads blobs'
    test.equal new univedo.Message("\x66foobar".b()).read(), "foobar", 'reads strings'
    # test.deepEqual new univedo.Message("\x66f\xc3\xb6obar".b()).read(), "föobar", 'reads strings'
    test.done()

  readsCollections: (test) ->
    test.deepEqual new univedo.Message("\x82\x63foo\x63bar".b()).read(), ["foo", "bar"], 'reads arrays'
    test.deepEqual new univedo.Message("\xa2\x63bar\x02\x63foo\x01".b()).read(), {foo: 1, bar: 2}, 'reads maps'
    test.done()

  readsTimes: (test) ->
    # test.deepEqual new univedo.Message("\xc9\x1b\x00\x04\xDA\x8B\x0D\xFF\x7F\x40".b()).read(), new Date(1366190677), 'reads datetimes'
    # test.deepEqual new univedo.Message("\xc8\x1b\x00\x04\xDA\x8B\x0D\xFF\x7F\x40".b()).read(), 1366190677, 'reads times'
    test.done()

  readsUuids: (test) ->
    test.equal new univedo.Message("\xc7\x50\x68\x4E\xF8\x95\x72\xA2\x42\x98\xBC\x5B\x58\x0F\x1C\x1D\x27\x07".b()).read(), "684ef895-72a2-4298-bc5b-580f1c1d2707", 'reads uuids'
    test.done()

  sendsSimple: (test) ->
    test.equal new univedo.Message().sendImpl(null), "\xf6", 'sends null'
    test.equal new univedo.Message().sendImpl(true), "\xf5", 'sends true'
    test.equal new univedo.Message().sendImpl(false), "\xf4", 'sends false'
    test.done()