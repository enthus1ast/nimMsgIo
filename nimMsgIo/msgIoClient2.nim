import asyncdispatch
import typesClient

proc newMsgIoClient(): MsgIoClient =
  result = new MsgIoClient

proc `transport=`(client: MsgIoClient, transport: ClientTransportBase) =
  client.transport = transport
  # result.transport = transport

proc connect(client: MsgIoClient, host: string, port: int): Future[bool] =
  client.transportConnect(client, host, port)

when isMainModule:
  import transports/clientTransportTcp
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
