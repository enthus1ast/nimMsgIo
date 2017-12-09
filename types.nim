#
#
#                   WebsocketIO
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
# import typesTransport
import asyncdispatch, options
# import typesMsgIo
import typesMsg
import roomLogic
import typesShared
export typesShared
type

  # Transport does something:
  ActionTransportSend* = proc (msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.closure, gcsafe.}
  ActionTransportServe* = proc (): Future[void] {.closure, gcsafe.}
  
  # Middleware gets informed:
  EventTransportClientConnected* = proc (msgio: MsgIoServer): Future[Option[ClientId]] {.closure, gcsafe.}  
  EventTransportClientDisconnected* = proc (msgio: MsgIoServer, clientId: ClientId): Future[void] {.closure, gcsafe.}  
  
  # Library user gets informed in his code:
  EventClientConnected* = proc (msgio: MsgIoServer, clientId: ClientId): Future[Option[ClientId]] {.closure, gcsafe.}  
  EventClientDisconnected* = EventTransportClientDisconnected

  # EventTransportJoinGroup* #= proc (msgio: MsgIoServer, clientId: ClientId): Future[void] {.closure, gcsafe.}  
  # EventTransportLeaveGroup*
  TransportBase* = object of RootObj
    proto*: string        ## the readable name of the transport
    send*: ActionTransportSend  ## transports sends a msg
    serve*: ActionTransportServe  ## transports sends a msg
    clientConnected*: EventTransportClientConnected
    clientDisconnected*: EventTransportClientDisconnected
    # hasClient*: -> bool
  MsgToServer* = object of MsgBase
  MsgFromServer = object of MsgBase
    sender*: string
  Transports* = seq[TransportBase]
  MsgIoServer* = ref object
    transports*: Transports
    roomLogic*: RoomLogic

    ## Transport Callbacks
    onTransportClientConnected*: EventTransportClientConnected
    onTransportClientDisconnected*: EventTransportClientDisconnected

    ## User Callbacks
    onClientConnected*: EventClientConnected
    onClientDisconnected*: EventClientDisconnected

  Client* = object 
    clientId: ClientId
    transportProtocol: string

  SerializerSerialize = proc (msg: MsgBase): string
  SerializerUnSerialize = proc (msgstr: string): MsgBase
  SerializerBase* = object of RootObj
    serialize*: SerializerSerialize
    unserialize*: SerializerUnSerialize

proc newClient*(clientId: ClientId = -1, transportProtocol: string): Client =
  result = Client()
  result.clientId = clientId
  result.transportProtocol = transportProtocol
