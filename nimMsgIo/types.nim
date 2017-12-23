#
#
#                      msgIo
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
import asyncdispatch, options
import roomLogic
import typesMsg
export typesMsg
import typesShared
export typesShared
import typesSerializer
export typesSerializer
import tables
export tables
type
  # Transport does something:
  ActionTransportSend* = proc (msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.closure, gcsafe.}
  ActionTransportServe* = proc (): Future[void] {.closure, gcsafe.}
  ActionTransportPing* = proc (clientId: ClientId): Future[bool] {.closure, gcsafe.}
  ActionTransportDisconnects* = proc (clientId: ClientId): Future[void] {.closure, gcsafe.}
  
  # Middleware gets informed:
  EventTransportClientConnecting* = proc (msgio: MsgIoServer, transport: TransportBase): Future[Option[ClientId]] {.closure, gcsafe.}  
  EventTransportClientConnected* = proc (msgio: MsgIoServer, clientId: ClientId, transport: TransportBase): Future[void] {.closure, gcsafe.}  
  EventTransportClientDisconnected* = proc (msgio: MsgIoServer, clientId: ClientId, transport: TransportBase): Future[void] {.closure, gcsafe.}  
  EventTransportMsg* = proc (msgio: MsgIoServer, msg: MsgBase, transport: TransportBase): Future[void] {.closure, gcsafe.}  

  # Library user gets informed in his code:
  EventClientConnecting* = proc (msgio: MsgIoServer, clientId: ClientId, transport: TransportBase): Future[Option[ClientId]] {.closure, gcsafe.}  
  EventClientConnected* = proc (msgio: MsgIoServer, clientId: ClientId, transport: TransportBase): Future[void] {.closure, gcsafe.}  
  EventClientDisconnected* = EventTransportClientDisconnected
  EventClientMsg* = EventTransportMsg

  # EventTransportLeaveGroup*
  TransportBase* = ref object of RootObj
    proto*: string        ## the readable name of the transport
    send*: ActionTransportSend  ## transports sends a msg
    serve*: ActionTransportServe  ## transports sends a msg
    ping*: ActionTransportPing ## transport pings a client
    disconnects*: ActionTransportDisconnects ## transport disconnects a client
    clientConnecting*: EventTransportClientConnecting
    clientDisconnected*: EventTransportClientDisconnected
    serializer*: SerializerBase
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
    onTransportMsg*: EventTransportMsg

    ## User Callbacks
    onClientConnecting*: EventClientConnecting
    onClientConnected*: EventClientConnected
    onClientDisconnected*: EventClientDisconnected
    onClientMsg*: EventClientMsg

  Client* = object 
    clientId: ClientId
    transportProtocol: string

proc newClient*(clientId: ClientId = -1, transportProtocol: string): Client =
  result = Client()
  result.clientId = clientId
  result.transportProtocol = transportProtocol