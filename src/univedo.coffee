# univedo
# https://github.com/lucas-clemente/univedo-js
#
# Copyright (c) 2013 Lucas Clemente
# Licensed under the MIT license.

((exports) ->

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
    FLOAT16: 25
    FLOAT32: 26
    FLOAT64: 27

  exports.cbor =
    read: (buf) ->
      typeInt = new DataView(buf).getUint8(0)
      major = typeInt >> 5

      switch major
        when VariantMajor.SIMPLE
          switch typeInt & 0x1F
            when VariantSimple.FALSE then false
            when VariantSimple.TRUE then true
            when VariantSimple.NULL then null



)(if exports? then exports else this)
