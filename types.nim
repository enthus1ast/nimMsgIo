#
#
#                   WebsocketIO
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
# import typesTransport
import asyncdispatch
# import typesMsgIo

type
  TransportSend* = proc (msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.closure, gcsafe.}
  TransportBase* = object of RootObj
    proto*: string
    send*: TransportSend
    # hasClient*: -> bool
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
  Transports* = seq[TransportBase]
  MsgIoServer* = ref object
    discard
    transports*: Transports
  ClientId* = int
  Client* = object 
    clientId: ClientId
    transportProtocol: string

proc newClient*(clientId: ClientId = -1, transportProtocol: string): Client =
  result = Client()
  result.clientId = clientId
  result.transportProtocol = transportProtocol
