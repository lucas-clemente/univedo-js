# univedo
# https://github.com/lucas-clemente/univedo-js
#
# Copyright (c) 2013 Lucas Clemente
# Licensed under the MIT license.

((exports) ->

  # UUID conversion raw <=> string
  byteToHex = []
  hexToByte = {}
  for i in [0..255]
    byteToHex[i] = (i + 0x100).toString(16).substr(1)
    hexToByte[byteToHex[i]] = i

  raw2Uuid = (buf) ->
    i = 0
    byteToHex[buf[i++]] + byteToHex[buf[i++]] +
    byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' +
    byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' +
    byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' +
    byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' +
    byteToHex[buf[i++]] + byteToHex[buf[i++]] +
    byteToHex[buf[i++]] + byteToHex[buf[i++]] +
    byteToHex[buf[i++]] + byteToHex[buf[i++]]

  # Create a ByteArray from a String
  byteArrayFromString = (s) ->
    buf = new ArrayBuffer(s.length)
    bufView = new Uint8Array(buf)
    for i in [0..s.length-1]
      bufView[i] = s.charCodeAt(i)
    buf

  # Create a ByteArray from an array of bytes (as number)
  byteArrayFromArray = (arr) ->
    byteArrayFromString(String.fromCharCode.apply(null, arr))

  concatArrayBufs = (buf1, buf2) ->
    tmp = new Uint8Array(buf1.byteLength + buf2.byteLength)
    tmp.set(new Uint8Array(buf1), 0)
    tmp.set(new Uint8Array(buf2), buf1.byteLength)
    tmp.buffer

  VariantMajor =
    UINT: 0
    NEGINT: 1
    BYTESTRING: 2
    TEXTSTRING: 3
    ARRAY: 4
    MAP: 5
    TAG: 6
    SIMPLE: 7

  VariantTag =
    DECIMAL: 4
    REMOTEOBJECT: 6
    UUID: 7
    TIME: 8
    DATETIME: 9
    SQL: 10

  VariantSimple =
    FALSE: 20
    TRUE: 21
    NULL: 22
    FLOAT32: 26
    FLOAT64: 27

  exports.Message = class Message
    constructor: (@buffer) ->
      @offset = 0


    # Receiving

    getDataView: (len) ->
      dv = new DataView(@buffer, @offset, len)
      @offset += len
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
        when VariantMajor.UINT then @getLen(typeInt)
        when VariantMajor.NEGINT then -@getLen(typeInt)-1
        when VariantMajor.SIMPLE
          switch typeInt & 0x1F
            when VariantSimple.FALSE then false
            when VariantSimple.TRUE then true
            when VariantSimple.NULL then null
            when VariantSimple.FLOAT32 then @getDataView(4).getFloat32(0)
            when VariantSimple.FLOAT64 then @getDataView(8).getFloat64(0)
            else throw "invalid simple in cbor protocol"
        when VariantMajor.BYTESTRING
          len = @getLen(typeInt)
          @buffer.slice(@offset, @offset += len)
        when VariantMajor.TEXTSTRING
          len = @getLen(typeInt)
          # TODO doesn't work for non-ascii, see test
          String.fromCharCode.apply(null, new Uint8Array(@buffer.slice(@offset, @offset += len)))
        when VariantMajor.ARRAY
          len = @getLen(typeInt)
          @read() for i in [0..len-1]
        when VariantMajor.MAP
          len = @getLen(typeInt)
          obj = {}
          for i in [0..len-1]
            obj[@read()] = @read()
          obj
        when VariantMajor.TAG
          tag = @getLen(typeInt)
          switch tag
            when VariantTag.TIME, VariantTag.DATETIME then new Date(@read())
            when VariantTag.UUID
              raw2Uuid(@read())
            else throw "invalid tag in cbor protocol"
        else throw "invalid major in cbor protocol"


    # Sending

    sendSimple: (type) ->
      byteArrayFromArray([VariantMajor.SIMPLE << 5 | type])

    sendTag: (tag) ->
      byteArrayFromArray([VariantMajor.TAG << 5 | tag])

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
        when obj == null then @sendSimple(VariantSimple.NULL)
        when obj == true then @sendSimple(VariantSimple.TRUE)
        when obj == false then @sendSimple(VariantSimple.FALSE)
        when typeof obj == "number"
          switch
            when obj >= 0 && obj < 0x100000000 && (obj % 1 == 0) then @sendLen(VariantMajor.UINT, obj)
            when obj < 0 && obj >= -0x100000000 && (obj % 1 == 0) then @sendLen(VariantMajor.NEGINT, -obj-1)
            else
              ba = new ArrayBuffer(8)
              new DataView(ba).setFloat64(0, obj)
              concatArrayBufs(@sendSimple(VariantSimple.FLOAT64), ba)
        else throw "unsupported object in cbor protocol"

  null
)(if exports? then exports else this)
