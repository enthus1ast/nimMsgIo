#
#
#                   WebsocketIO
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## json serializer for transport data exchange
import ../types
import json

type 
  SerializerJson = object of SerializerBase
  # SerializerBase = object of RootObj
  #   serialize: proc (msg: MsgBase): string
  #   unserialize: proc (msgstr: string): MsgBase

proc newSerializerJson(): SerializerJson =
  result = SerializerJson()
  result.serialize = proc (msg: MsgBase): string = 
    discard
  result.unserialize = proc (msgstr: string): MsgBase = 
    discard
# proc toStr(msg: MsgBase): string =
  