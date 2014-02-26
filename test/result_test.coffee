univedo = require('../dist/univedo.js').univedo
assert = require 'assert'

URL = "ws://localhost:9000/f8018f09-fb75-4d3d-8e11-44b2dc796130"
OPTS =
  9744: "marvin"

describe 'Result', ->
  beforeEach (done) ->
    @session = new univedo.Session URL, OPTS, =>
      @session.getPerspective 'cefb4ed2-4ce3-4825-8550-b68a3c142f0a', (p) =>
        p.query (q) =>
          @query = q
          done()

  afterEach ->
    @session.close()

  it 'runs selects', (done) ->
    @query.prepare 'select count(*) from fields_inclusive', (s) ->
      s.execute (r) ->
        assert r.rows[0][0] > 0
        assert.deepEqual null, r.affected_rows
        assert.deepEqual null, r.num_affected_rows
        assert.deepEqual null, r.last_inserted_id
        done()

  it 'runs inserts', (done) ->
    @query.prepare 'insert into dummy default values', (s) ->
      s.execute (r) ->
        assert.deepEqual [], r.rows
        assert.deepEqual null, r.affected_rows
        assert.deepEqual null, r.num_affected_rows
        assert r.last_inserted_id >= 0
        done()

  it 'runs inserts with binds', (done) ->
    @query.prepare 'insert into dummy (dummy_int8) values (?)', (s) =>
      s.execute {0: 42}, (r) =>
        id = r.last_inserted_id
        @query.prepare 'select dummy_int8 from dummy where id = ?', (s) ->
          s.execute {0: id}, (r) ->
            assert.deepEqual [[42]], r.rows
            done()

  it 'runs updates', (done) ->
    @query.prepare 'insert into dummy (dummy_int8) values (23)', (s) =>
      s.execute (r) =>
        id = r.last_inserted_id
        @query.prepare 'update dummy set dummy_int8 = 42 where id = ?', (s) =>
          s.execute {0: id}, (r) =>
            assert.deepEqual [], r.rows
            assert.deepEqual [id], r.affected_rows
            assert.deepEqual 1, r.num_affected_rows
            assert.deepEqual null, r.last_inserted_id
            @query.prepare 'select dummy_int8 from dummy where id = ?', (s) ->
              s.execute {0: id}, (r) ->
                assert.deepEqual [[42]], r.rows
                done()
