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
  SerializerJson* = object of SerializerBase
  # SerializerBase = object of RootObj
  #   serialize: proc (msg: MsgBase): string
  #   unserialize: proc (msgstr: string): MsgBase

proc serialize(msg: MsgBase): string =
  result = $ %* msg

proc unserialize(msgstr: string): MsgBase =
  result = MsgBase()
  let jnode = msgstr.parseJson()
  result = jnode.to(MsgBase)
  
proc newSerializerJson*(): SerializerJson =
  result = SerializerJson()
  result.serialize = proc (msg: MsgBase): string = 
    return serialize(msg)
  result.unserialize = proc (msgstr: string): MsgBase = 
    return unserialize(msgstr)

when isMainModule:
  var msg = MsgBase()
  msg.target = "123"
  msg.event = "some enduser event here"
  msg.payload = "some enduser payload here"
  let ser = msg.serialize()
  var msg2 = ser.unserialize()
  assert msg == msg2
  