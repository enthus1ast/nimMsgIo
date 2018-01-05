#
#
#                      msgIo
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## json serializer for transport data exchange
import streams, options
import ../typesSerializer
import msgpack4nim

type 
  SerializerMsgPack* = object of SerializerBase
  # SerializerBase = object of RootObj
  #   serialize: proc (msg: MsgBase): string
  #   unserialize: proc (msgstr: string): MsgBase


proc serialize(msg: MsgBase): Option[string] =
  var ss = newStringStream()
  try:
    ss.pack(msg)
    return some[string](ss.data)
  except:
    return

proc unserialize(msgstr: string): Option[MsgBase] =
  var msg = newMsgBase()
  try:
    var ss = newStringStream(msgstr)
    ss.unpack(msg)
    return some[MsgBase](msg)
  except:
    return

proc newSerializerMsgPack*(): SerializerMsgPack =
  result = SerializerMsgPack()
  result.serialize = proc (msg: MsgBase): Option[string] = 
    return serialize(msg)
  result.unserialize = proc (msgstr: string): Option[MsgBase] = 
    return unserialize(msgstr)

when isMainModule:
  var msg = newMsgBase()
  msg.target = "123"
  msg.event = "some enduser event here"
  msg.payload = "some enduser payload here"
  let ser = msg.serialize()
  var msg2 = ser.unserialize()
  assert msg == msg2
  