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
    return  byteToHex[buf[i++]] + byteToHex[buf[i++]] +
            byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' +
            byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' +
            byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' +
            byteToHex[buf[i++]] + byteToHex[buf[i++]] + '-' +
            byteToHex[buf[i++]] + byteToHex[buf[i++]] +
            byteToHex[buf[i++]] + byteToHex[buf[i++]] +
            byteToHex[buf[i++]] + byteToHex[buf[i++]]

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
      String.fromCharCode(VariantMajor.SIMPLE << 5 | type)

    sendTag: (tag) ->
      String.fromCharCode(VariantMajor.TAG << 5 | tag)

    sendImpl: (obj) ->
      switch obj
        when null then @sendSimple(VariantSimple.NULL)
        when true then @sendSimple(VariantSimple.TRUE)
        when false then @sendSimple(VariantSimple.FALSE)

  null
)(if exports? then exports else this)
