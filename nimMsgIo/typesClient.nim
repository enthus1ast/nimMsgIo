import asyncdispatch
import typesMsg
export typesMsg
import typesSerializer
export typesSerializer

type
  # Transport does something:
  ActionTransportConnect* = proc (client: MsgIoClient, host: string, port: int): Future[bool] {.closure, gcsafe.}
  # Middleware gets informed:
  EventTransportClientConnected* = proc (client: MsgIoClient): Future[bool] {.closure, gcsafe.}
  EventTransportClientDisconnected* = proc (client: MsgIoClient): Future[void] {.closure, gcsafe.}
  EventTransportClientMessage* = proc (client: MsgIoClient, msg: MsgBase): Future[void] {.closure, gcsafe.}
  # Library user gets informed in his code:
  EventClientConnected* = proc (client: MsgIoClient): Future[void] {.closure, gcsafe.}
  EventClientDisconnected* = proc (client: MsgIoClient): Future[void] {.closure, gcsafe.}
  EventClientMessage* = proc (client: MsgIoClient, msg: MsgBase): Future[void] {.closure, gcsafe.}
  #---
  MsgIoClient* = ref object
    transport*: ClientTransportBase
    onConnected*: EventClientConnected
    onDisconncted*: EventClientDisconnected
    onMessage*: EventClientMessage
    transportConnect*: ActionTransportConnect

  ClientTransportBase* = ref object of RootObj
    msgIoClient*: MsgIoClient
    serializer*: SerializerBase
    onTransportConnected*: EventTransportClientConnected
    onTransportDisconncted*: EventTransportClientDisconnected
    onTransportMessage*: EventTransportClientMessage