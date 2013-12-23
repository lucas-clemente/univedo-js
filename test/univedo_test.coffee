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
    test.equal univedo.cbor.read("\xf6".b()), null, 'reads null'
    test.equal univedo.cbor.read("\xf5".b()), true, 'reads true'
    test.equal univedo.cbor.read("\xf4".b()), false, 'reads false'
    test.done()
