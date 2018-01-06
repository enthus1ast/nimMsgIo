#
#
#                      msgIo
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
type
  MsgType* = enum
    CLIENT_TO_GROUP
    CLIENT_TO_SERVER
    SERVER_TO_CLIENT
    SERVER_TO_GROUP
    CLIENT_TO_CLIENT
  # MsgTypeSend* = enum
  #   TO_GROUP
  #   TO_SERVER
  #   TO_CLIENT
  # MsgServerSends =

  # MsgClientSends = 
  
  MsgBase* = object of RootObj
    namespace*: string
    # target*: string ## TODO remove this?
    # msgType*: MsgType
    event*: string
    payload*: string
    # msgId*: int
  
  # MsgRecv* = object of MsgBase
  #   tType*: MsgType
  # MsgSend* = object of MsgBase
  #   targetType*: MsgTypeSend
  # # MsgToServer* = object

proc newMsgBase*(): MsgBase =
  result = MsgBase()
  result.namespace = ""
  # result.target = ""
  result.event = ""
  result.payload = ""
