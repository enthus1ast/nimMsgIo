import asyncdispatch
import typesClient

proc newMsgIoClient(): MsgIoClient =
  result = new MsgIoClient

proc `transport=`(client: MsgIoClient, transport: ClientTransportBase) =
  client.transport = transport
  # result.transport = transport

proc connect(client: MsgIoClient, host: string, port: int): Future[bool] {.async.} =
  result = await client.transportConnect(client, host, port)

when isMainModule:
  import transports/clientTransportTcp
  import serializer/serializerJson
  import serializer/serializerMsgPack

  var 
    client: MsgIoClient
    msg: MsgBase

  client = newMsgIoClient()
  client.transport = client.newClientTransportTcp(
    serializer = newSerializerJson()
  )
  
  client.onConnected = proc (client: MsgIoClient): Future[void] {.closure, gcsafe, async.} =
    echo "CLIENT CONNECTED"
    return

  client.onDisconncted = proc (client: MsgIoClient): Future[void] {.closure, gcsafe, async.} =
    echo "CLIENT DISCONNECTED"
    return

  # client.onMessage = proc (client: MsgIoClient, msg: MsgBase): Future[void] {.closure, gcsafe.} =
  #   discard
    # client.send(msg.event, "GOT MESSAGE")

  # client.onEvent = proc(client: MsgIoClient, msg: MsgBase): Future[void] {.closure, gcsafe.} =)
  #   echo "CLIENT DISCONNECTED"

  echo waitFor client.connect("127.0.0.1", 9001) # Same as client.onConnect Callback
  # msg = await client.send("event", "data")
  
  runForever()
  # echo result.payload
