import types
import asyncdispatch

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

  

## TRANSPORT TCP
import asyncnet

type
  ClientTransportTcp* = ref object of ClientTransportBase
    client*: AsyncSocket

proc connectTcp(client: ClientTransportTcp, host: string, port: int): Future[bool] {.async.} =
  discard

proc newClientTransportTcp(client: MsgIoClient, serializer: SerializerBase): ClientTransportTcp =
  result = new ClientTransportTcp
  result.client = newAsyncSocket()
  result.msgIoClient = client
  result.serializer = serializer
  var transport = result
  client.transportConnect = proc (client: MsgIoClient, host: string, port: int): Future[bool] {.closure, gcsafe.} =
    transport.connectTcp(host, port)
##

proc newMsgIoClient(): MsgIoClient =
  result = new MsgIoClient

proc `transport=`(client: MsgIoClient, transport: ClientTransportBase) =
  client.transport = transport
  # result.transport = transport

proc connect(client: MsgIoClient, host: string, port: int): Future[bool] =
  client.transportConnect(client, host, port)

when isMainModule:
  # import transports/client/transportWebSocket
  import serializer/serializerJson
  import serializer/serializerMsgPack

  var client = newMsgIoClient()
  client.transport = client.newClientTransportTcp(newSerializerJson())
  
  client.onConnected = proc (client: MsgIoClient): Future[void] {.closure, gcsafe.} =
    echo "CLIENT CONECTED"

  client.onDisconncted = proc (client: MsgIoClient): Future[void] {.closure, gcsafe.} =
    echo "CLIENT DISCONNECTED"

  client.onMessage = proc (client: MsgIoClient, msg: MsgBase): Future[void] {.closure, gcsafe.} =
    discard
    # client.send(msg.event, "GOT MESSAGE")

  # client.onEvent = proc(client: MsgIoClient, msg: MsgBase): Future[void] {.closure, gcsafe.} =)
  #   echo "CLIENT DISCONNECTED"

  echo $(waitFor client.connect("127.0.0.1", 1234)) # Same as client.onConnect Callback
  # var result: MsgBase = await client.send("event", "data")
  # echo result.payload
