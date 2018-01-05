#
#
#                      msgIo
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## json serializer for transport data exchange
# import ../types
import ../typesSerializer
import json, options

type 
  SerializerJson* = object of SerializerBase
  # SerializerBase = object of RootObj
  #   serialize: proc (msg: MsgBase): string
  #   unserialize: proc (msgstr: string): MsgBase

proc serialize(msg: MsgBase): Option[string] =
  try:
    result = some[string]($ %* msg)
  except:
    return

proc unserialize(msgstr: string): Option[MsgBase] =
  try:
    let jnode = msgstr.parseJson()
    result = some[MsgBase](jnode.to(MsgBase))
  except:
    return
  
proc newSerializerJson*(): SerializerJson =
  result = SerializerJson()
  result.serialize = proc (msg: MsgBase): Option[string] = 
    return serialize(msg)
  result.unserialize = proc (msgstr: string): Option[MsgBase] = 
    return unserialize(msgstr)

when isMainModule:
  var msg = newMsgBase()
  msg.target = "123"
  msg.event = "some enduser event here"
  msg.payload = "some enduser payload here"
  let ser = msg.serialize().get()
  var msg2 = ser.unserialize().get()
  assert msg == msg2
  