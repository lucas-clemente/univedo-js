class Connection extends univedo.RemoteObject
  constructor: (session, id) ->
    super(session, id, ['ping', 'getPerspective'])
univedo.remote_classes['com.univedo.connection'] = Connection

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

  execute: (binds) ->
    args = if binds then [binds] else []
    @_callRom 'execute', args
    .then (result) ->
      new Promise (resolve, reject) ->
        result._oncomplete = resolve
univedo.remote_classes['com.univedo.statement'] = Statement

class Result extends univedo.RemoteObject
  constructor: (session, id) ->
    super(session, id)
    @_on 'setError', @_onerror
    # SELECT
    @rows = []
    @_on 'appendRow', (row) ->
      @rows.push(row)
    @_on 'setComplete', ->
      @_oncomplete(this)
    # UPDATE, DELETE, LINK
    @affected_rows = null
    @num_affected_rows = null
    @_on 'setAffectedRecords', (r) ->
      @affected_rows = r
      @num_affected_rows = @affected_rows.length
    # INSERT
    @last_inserted_id = null
    @_on 'setRecord', (r) ->
      @last_inserted_id = r

  _onerror: (msg) ->
    throw Error msg
  _oncomplete: (res) ->

univedo.remote_classes['com.univedo.result'] = Result
