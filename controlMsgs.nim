#
#
#                   WebsocketIO
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
type
  MsgType* = enum
    GROUP
    CLIENT
    SERVER
  MsgBase = object of RootObj
    target*: string
    sourceType: MsgType
    targetType: MsgType
    event*: string
    payload*: string
    # msgId*: int
  MsgToServer* = object of MsgBase
  MsgFromServer = object of MsgBase
    sender*: string
