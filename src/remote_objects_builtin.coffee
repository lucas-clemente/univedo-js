class Connection extends univedo.RemoteObject
  constructor: (session, id) ->
    super(session, id, ['ping', 'getPerspective'])
univedo.remote_classes['com.univedo.connection'] = Connection

class Perspective extends univedo.RemoteObject
  constructor: (session, id) ->
    super(session, id, ['query'])
univedo.remote_classes['com.univedo.perspective'] = Perspective
