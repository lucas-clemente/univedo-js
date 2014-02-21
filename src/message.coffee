CborMajor =
  UINT: 0
  NEGINT: 1
  BYTESTRING: 2
  TEXTSTRING: 3
  ARRAY: 4
  MAP: 5
  TAG: 6
  SIMPLE: 7

CborTag =
  DATETIME: 0
  TIME: 1
  DECIMAL: 4
  REMOTEOBJECT: 6
  UUID: 7
  RECORD: 8

CborSimple =
  FALSE: 20
  TRUE: 21
  NULL: 22
  FLOAT32: 26
  FLOAT64: 27

exports.Message = class Message
  constructor: (@recvBuffer) ->
    @recvOffset = 0
    @sendBuffer = new ArrayBuffer(0)


  # Receiving

  _getDataView: (len) ->
    dv = new DataView(@recvBuffer, @recvOffset, len)
    @recvOffset += len
    dv

  _getLen: (typeInt) ->
    smallLen = typeInt & 0x1F
    switch smallLen
      when 24
        @_getDataView(1).getUint8(0)
      when 25
        @_getDataView(2).getUint16(0)
      when 26
        @_getDataView(4).getUint32(0)
      when 27
        throw Error "int64 not yet supported in javascript!"
      else
        smallLen

  shift: ->
    typeInt = @_getDataView(1).getUint8(0)
    major = typeInt >> 5

    switch major
      when CborMajor.UINT then @_getLen(typeInt)
      when CborMajor.NEGINT then -@_getLen(typeInt)-1
      when CborMajor.SIMPLE
        switch typeInt & 0x1F
          when CborSimple.FALSE then false
          when CborSimple.TRUE then true
          when CborSimple.NULL then null
          when CborSimple.FLOAT32 then @_getDataView(4).getFloat32(0)
          when CborSimple.FLOAT64 then @_getDataView(8).getFloat64(0)
          else throw Error "invalid simple in cbor protocol"
      when CborMajor.BYTESTRING
        len = @_getLen(typeInt)
        @recvBuffer.slice(@recvOffset, @recvOffset += len)
      when CborMajor.TEXTSTRING
        len = @_getLen(typeInt)
        # TODO doesn't work for non-ascii, see test
        arr = new Uint8Array(@recvBuffer.slice(@recvOffset, @recvOffset += len))
        String.fromCharCode.apply(null, arr)
      when CborMajor.ARRAY
        len = @_getLen(typeInt)
        @shift() for i in [0..len-1]
      when CborMajor.MAP
        len = @_getLen(typeInt)
        obj = {}
        for i in [0..len-1]
          obj[@shift()] = @shift()
        obj
      when CborMajor.TAG
        tag = @_getLen(typeInt)
        switch tag
          when CborTag.DATETIME then new Date(@shift())
          when CborTag.TIME then new Date(@shift())
          when CborTag.UUID
            raw2Uuid(@shift())
          when CborTag.RECORD then @shift()
          else throw Error "invalid tag in cbor protocol"
      else throw Error "invalid major in cbor protocol"


  # Sending

  send: (obj) ->
    @sendBuffer = concatArrayBufs([@sendBuffer, @_sendImpl(obj)])

  _sendSimple: (type) ->
    byteArrayFromArray([CborMajor.SIMPLE << 5 | type])

  _sendTag: (tag) ->
    byteArrayFromArray([CborMajor.TAG << 5 | tag])

  _sendLen: (major, len) ->
    typeInt = major << 5
    switch
      when len <= 23
        byteArrayFromArray([typeInt | len])
      when len < 0x100
        byteArrayFromArray([typeInt | 24, len])
      when len < 0x10000
        byteArrayFromArray([typeInt | 25, len >> 8, len & 0xff])
      when len < 0x100000000
        byteArrayFromArray([
          typeInt | 26, len >> 24, len >> 16, len >> 8, len & 0xff
        ])
      else throw Error "_sendLen() called with non-uint"

  _sendImpl: (obj) ->
    switch
      when obj == null then @_sendSimple(CborSimple.NULL)
      when obj == true then @_sendSimple(CborSimple.TRUE)
      when obj == false then @_sendSimple(CborSimple.FALSE)
      when typeof obj == "number"
        switch
          when obj >= 0 && obj < 0x100000000 && (obj % 1 == 0)
            @_sendLen(CborMajor.UINT, obj)
          when obj < 0 && obj >= -0x100000000 && (obj % 1 == 0)
            @_sendLen(CborMajor.NEGINT, -obj-1)
          else
            ba = new ArrayBuffer(8)
            new DataView(ba).setFloat64(0, obj)
            concatArrayBufs([
              @_sendSimple(CborSimple.FLOAT64),
              ba
            ])
      when typeof obj == "string"
        concatArrayBufs([
          @_sendLen(CborMajor.TEXTSTRING, obj.length),
          byteArrayFromString(obj)
        ])
      when obj.constructor.name == "ArrayBuffer"
        concatArrayBufs([
          @_sendLen(CborMajor.BYTESTRING, obj.byteLength),
          obj
        ])
      when obj.constructor.name == "Array"
        bufs = [@_sendLen(CborMajor.ARRAY, obj.length)]
        bufs.push(@_sendImpl(v)) for v in obj
        concatArrayBufs(bufs)
      when obj.constructor.name == "Object"
        keys = Object.keys(obj)
        bufs = [@_sendLen(CborMajor.MAP, keys.length)]
        for key in keys
          bufs.push(@_sendImpl(key))
          bufs.push(@_sendImpl(obj[key]))
        concatArrayBufs(bufs)
      when obj.constructor.name == "Date"
        concatArrayBufs([
          @_sendTag(CborTag.DATETIME),
          @_sendImpl(obj.toISOString())
        ])
      else throw Error "unsupported object in cbor protocol"
