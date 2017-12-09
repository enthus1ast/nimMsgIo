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
    TGROUP
    TCLIENT
    TSERVER
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


type # Server
  ClientId* = int
  Client* = object 
    clientId: ClientId
    transportProtocol: string

proc newClient*(clientId: ClientId = -1, transportProtocol: string): Client =
  result = Client()
  result.clientId = clientId
  result.transportProtocol = transportProtocol