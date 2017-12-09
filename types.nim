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

  # Transport does something:
  ActionTransportSend* = proc (msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.closure, gcsafe.}
  ActionTransportServe* = proc (): Future[void] {.closure, gcsafe.}
  
  # Middleware gets informed:
  EventTransportClientConnected* = proc (msgio: MsgIoServer, clientId: ClientId): Future[bool] {.closure, gcsafe.}  
  EventTransportClientDisconnected* = proc (msgio: MsgIoServer, clientId: ClientId): Future[void] {.closure, gcsafe.}  
  # EventTransportJoinGroup* #= proc (msgio: MsgIoServer, clientId: ClientId): Future[void] {.closure, gcsafe.}  
  # EventTransportLeaveGroup*
  TransportBase* = object of RootObj
    proto*: string        ## the readable name of the transport
    send*: ActionTransportSend  ## transports sends a msg
    serve*: ActionTransportServe  ## transports sends a msg
    clientConnected*: EventTransportClientConnected
    clientDisconnected*: EventTransportClientDisconnected
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
    transports*: Transports
    onClientConnected*: EventTransportClientConnected
    onClientDisconnected*: EventTransportClientDisconnected
  ClientId* = int
  Client* = object 
    clientId: ClientId
    transportProtocol: string

proc newClient*(clientId: ClientId = -1, transportProtocol: string): Client =
  result = Client()
  result.clientId = clientId
  result.transportProtocol = transportProtocol
