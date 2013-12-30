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

  getDataView: (len) ->
    dv = new DataView(@recvBuffer, @recvOffset, len)
    @recvOffset += len
    dv

  getLen: (typeInt) ->
    smallLen = typeInt & 0x1F
    switch smallLen
      when 24
        @getDataView(1).getUint8(0)
      when 25
        @getDataView(2).getUint16(0)
      when 26
        @getDataView(4).getUint32(0)
      when 27
        throw "int64 not yet supported in javascript!"
      else
        smallLen

  read: ->
    typeInt = @getDataView(1).getUint8(0)
    major = typeInt >> 5

    switch major
      when CborMajor.UINT then @getLen(typeInt)
      when CborMajor.NEGINT then -@getLen(typeInt)-1
      when CborMajor.SIMPLE
        switch typeInt & 0x1F
          when CborSimple.FALSE then false
          when CborSimple.TRUE then true
          when CborSimple.NULL then null
          when CborSimple.FLOAT32 then @getDataView(4).getFloat32(0)
          when CborSimple.FLOAT64 then @getDataView(8).getFloat64(0)
          else throw "invalid simple in cbor protocol"
      when CborMajor.BYTESTRING
        len = @getLen(typeInt)
        @recvBuffer.slice(@recvOffset, @recvOffset += len)
      when CborMajor.TEXTSTRING
        len = @getLen(typeInt)
        # TODO doesn't work for non-ascii, see test
        String.fromCharCode.apply(null, new Uint8Array(@recvBuffer.slice(@recvOffset, @recvOffset += len)))
      when CborMajor.ARRAY
        len = @getLen(typeInt)
        @read() for i in [0..len-1]
      when CborMajor.MAP
        len = @getLen(typeInt)
        obj = {}
        for i in [0..len-1]
          obj[@read()] = @read()
        obj
      when CborMajor.TAG
        tag = @getLen(typeInt)
        switch tag
          when CborTag.DATETIME then new Date(@read())
          when CborTag.TIME then new Date(@read())
          when CborTag.UUID
            raw2Uuid(@read())
          when CborTag.RECORD then @read()
          else throw "invalid tag in cbor protocol"
      else throw "invalid major in cbor protocol"


  # Sending

  send: (obj) ->
    @sendBuffer = concatArrayBufs([@sendBuffer, @sendImpl(obj)])

  sendSimple: (type) ->
    byteArrayFromArray([CborMajor.SIMPLE << 5 | type])

  sendTag: (tag) ->
    byteArrayFromArray([CborMajor.TAG << 5 | tag])

  sendLen: (major, len) ->
    typeInt = major << 5
    switch
      when len <= 23
        byteArrayFromArray([typeInt | len])
      when len < 0x100
        byteArrayFromArray([typeInt | 24, len])
      when len < 0x10000
        byteArrayFromArray([typeInt | 25, len >> 8, len & 0xff])
      when len < 0x100000000
        byteArrayFromArray([typeInt | 26, len >> 24, len >> 16, len >> 8, len & 0xff])
      else throw "sendLen() called with non-uint"

  sendImpl: (obj) ->
    switch
      when obj == null then @sendSimple(CborSimple.NULL)
      when obj == true then @sendSimple(CborSimple.TRUE)
      when obj == false then @sendSimple(CborSimple.FALSE)
      when typeof obj == "number"
        switch
          when obj >= 0 && obj < 0x100000000 && (obj % 1 == 0) then @sendLen(CborMajor.UINT, obj)
          when obj < 0 && obj >= -0x100000000 && (obj % 1 == 0) then @sendLen(CborMajor.NEGINT, -obj-1)
          else
            ba = new ArrayBuffer(8)
            new DataView(ba).setFloat64(0, obj)
            concatArrayBufs([
              @sendSimple(CborSimple.FLOAT64),
              ba
            ])
      when typeof obj == "string"
        concatArrayBufs([
          @sendLen(CborMajor.TEXTSTRING, obj.length),
          byteArrayFromString(obj)
        ])
      when obj.constructor.name == "ArrayBuffer"
        concatArrayBufs([
          @sendLen(CborMajor.BYTESTRING, obj.byteLength),
          obj
        ])
      when obj.constructor.name == "Array"
        bufs = [@sendLen(CborMajor.ARRAY, obj.length)]
        bufs.push(@sendImpl(v)) for v in obj
        concatArrayBufs(bufs)
      when obj.constructor.name == "Object"
        keys = Object.keys(obj)
        bufs = [@sendLen(CborMajor.MAP, keys.length)]
        for key in keys
          bufs.push(@sendImpl(key)) 
          bufs.push(@sendImpl(obj[key])) 
        concatArrayBufs(bufs)
      when obj.constructor.name == "Date"
        concatArrayBufs([
          @sendTag(CborTag.DATETIME),
          @sendImpl(obj.toISOString())
        ])
      else throw "unsupported object in cbor protocol"
