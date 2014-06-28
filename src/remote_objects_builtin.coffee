class Connection extends univedo.RemoteObject
  constructor: (session, id) ->
    super(session, id, ['ping', 'getPerspective', 'applyUts'])
univedo.remote_classes['com.univedo.session'] = Connection

class Perspective extends univedo.RemoteObject
  constructor: (session, id) ->
    super(session, id, ['query'])
univedo.remote_classes['com.univedo.perspective'] = Perspective

class Query extends univedo.RemoteObject
  constructor: (session, id) ->
    super(session, id, ['prepare'])
univedo.remote_classes['com.univedo.query'] = Query

class Statement extends univedo.RemoteObject
  constructor: (session, id) ->
    super(session, id)
    @_on 'setColumnNames', ->

  execute: (binds = {}) ->
    @_callRom("execute", [binds])
univedo.remote_classes['com.univedo.statement'] = Statement

class Result extends univedo.RemoteObject
  # TODO error handling
  constructor: (session, id) ->
    super(session, id)
    @_on 'setError', @_onerror
    # SELECT
    @_rows = []
    @rows = new Promise (resolve, reject) =>
      @_on 'setTuple', (row) ->
        @_rows.push(row)
      @_on 'setComplete', ->
        resolve(@_rows)
    # UPDATE, DELETE, LINK
    @n_affected_rows = new Promise (resolve, reject) =>
      @_on 'setNAffectedRecords', (records) ->
        resolve(records)
    # INSERT
    @last_inserted_id = new Promise (resolve, reject) =>
      @_on 'setId', (r) ->
        resolve(r)

  _onerror: (msg) ->
    throw Error msg
univedo.remote_classes['com.univedo.result'] = Result
