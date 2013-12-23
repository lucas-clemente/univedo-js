univedo = require('../lib/univedo.js')

String.prototype.b = ->
  buf = new ArrayBuffer(@length)
  bufView = new Uint8Array(buf)
  for i in [0..@length]
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
