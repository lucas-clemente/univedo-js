univedo = require('../dist/univedo.js').univedo
assert = require 'assert'

URL = "ws://localhost:9000/f8018f09-fb75-4d3d-8e11-44b2dc796130"
OPTS =
  9744: "marvin"

describe 'Result', ->
  beforeEach (done) ->
    @session = new univedo.Session URL, OPTS, (s) =>
      s.getPerspective 'cefb4ed2-4ce3-4825-8550-b68a3c142f0a'
      .then (p) ->
        p.query()
      .then (q) =>
        @query = q
        done()

  afterEach ->
    @session.close()

  it 'runs selects', (done) ->
    @query.prepare 'select count(*) from fields_inclusive'
    .then (s) ->
      s.execute()
    .then (r) ->
      assert r.rows[0][0] > 0
      assert.deepEqual null, r.affected_rows
      assert.deepEqual null, r.num_affected_rows
      assert.deepEqual null, r.last_inserted_id
      done()

  it 'runs inserts', (done) ->
    @query.prepare 'insert into dummy default values'
    .then (s) ->
      s.execute()
    .then (r) ->
      assert.deepEqual [], r.rows
      assert.deepEqual null, r.affected_rows
      assert.deepEqual null, r.num_affected_rows
      assert r.last_inserted_id >= 0
      done()

  it 'runs inserts with binds', (done) ->
    @query.prepare 'insert into dummy (dummy_int8) values (?)'
    .then (s) ->
      s.execute {0: 42}
    .then (r) =>
      id = r.last_inserted_id
      @query.prepare 'select dummy_int8 from dummy where id = ?'
      .then (s) ->
        s.execute {0: id}
      .then (r) ->
        assert.deepEqual [[42]], r.rows
        done()

  it 'runs updates', (done) ->
    @query.prepare 'insert into dummy (dummy_int8) values (23)'
    .then (s) ->
      s.execute()
    .then (r) =>
      id = r.last_inserted_id
      @query.prepare 'update dummy set dummy_int8 = 42 where id = ?'
      .then (s) ->
        s.execute {0: id}
      .then (r) =>
        assert.deepEqual [], r.rows
        assert.deepEqual [id], r.affected_rows
        assert.deepEqual 1, r.num_affected_rows
        assert.deepEqual null, r.last_inserted_id
        @query.prepare 'select dummy_int8 from dummy where id = ?'
        .then (s) ->
          s.execute {0: id}
        .then (r) ->
          assert.deepEqual [[42]], r.rows
          done()
