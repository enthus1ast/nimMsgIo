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
import roomLogic
import typesMsg
export typesMsg
import typesShared
export typesShared
import tables
export tables
type

  # Transport does something:
  ActionTransportSend* = proc (msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.closure, gcsafe.}
  ActionTransportServe* = proc (): Future[void] {.closure, gcsafe.}
  
  # Middleware gets informed:
  EventTransportClientConnecting* = proc (msgio: MsgIoServer): Future[Option[ClientId]] {.closure, gcsafe.}  
  EventTransportClientConnected* = proc (msgio: MsgIoServer, clientId: ClientId, transport: TransportBase): Future[void] {.closure, gcsafe.}  
  EventTransportClientDisconnected* = proc (msgio: MsgIoServer, clientId: ClientId, transport: TransportBase): Future[void] {.closure, gcsafe.}  
  
  # Library user gets informed in his code:
  EventClientConnecting* = proc (msgio: MsgIoServer, clientId: ClientId): Future[Option[ClientId]] {.closure, gcsafe.}  
  EventClientConnected* = proc (msgio: MsgIoServer, clientId: ClientId): Future[void] {.closure, gcsafe.}  
  EventClientDisconnected* = EventTransportClientDisconnected

  # EventTransportJoinGroup* #= proc (msgio: MsgIoServer, clientId: ClientId): Future[void] {.closure, gcsafe.}  
  # EventTransportLeaveGroup*
  TransportBase* = ref object of RootObj
    proto*: string        ## the readable name of the transport
    send*: ActionTransportSend  ## transports sends a msg
    serve*: ActionTransportServe  ## transports sends a msg
    clientConnecting*: EventTransportClientConnecting
    clientDisconnected*: EventTransportClientDisconnected
    # hasClient*: -> bool
  MsgToServer* = object of MsgBase
  MsgFromServer = object of MsgBase
    sender*: string
  Transports* = seq[TransportBase]
  MsgIoServer* = ref object
    clients*: TableRef[ClientId, TransportBase]
    transports*: Transports
    roomLogic*: RoomLogic

    ## Transport Callbacks
    onTransportClientConnecting*: EventTransportClientConnecting
    onTransportClientConnected*: EventTransportClientConnected
    onTransportClientDisconnected*: EventTransportClientDisconnected

    ## User Callbacks
    onClientConnecting*: EventClientConnecting
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
