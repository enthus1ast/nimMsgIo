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
import streams
import msgpack4nim

type 
  SerializerMsgPack* = object of SerializerBase
  # SerializerBase = object of RootObj
  #   serialize: proc (msg: MsgBase): string
  #   unserialize: proc (msgstr: string): MsgBase


proc serialize(msg: MsgBase): string =
  var ss = newStringStream()
  ss.pack(msg)
  return ss.data

proc unserialize(msgstr: string): MsgBase =
  result = MsgBase()
  var ss = newStringStream(msgstr)
  ss.unpack(result)

proc newSerializerMsgPack*(): SerializerMsgPack =
  result = SerializerMsgPack()
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
  