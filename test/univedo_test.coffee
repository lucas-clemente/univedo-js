univedo = require('../lib/univedo.js')

exports['awesome'] =
  setUp: (done) ->
    done()

  'no args': (test) ->
    test.expect 1
    test.equal univedo.awesome(), 'awesome', 'should be awesome.'
    test.done()
