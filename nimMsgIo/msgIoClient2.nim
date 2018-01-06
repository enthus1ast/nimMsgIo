when not defined(js):
  import asyncdispatch
else:
  import asyncjs
import typesClient
export typesClient

proc newMsgIoClient*(): MsgIoClient =
  result = new MsgIoClient

proc `transport=`*(client: MsgIoClient, transport: ClientTransportBase) =
  client.transport = transport

proc connect*(client: MsgIoClient, host: string, port: int): Future[bool] {.async.} =
  result = await client.transportConnect(client, host, port)

proc send*(client: MsgIoClient, event: string, payload: string): Future[void] {.async.} =
  var msg = newMsgBase()
  msg.event = event
  msg.payload = payload
  await client.transportSend(client, msg)

when isMainModule:
  import transports/clientTransportTcp
  import serializer/serializerJson
  import serializer/serializerMsgPack

  var client: MsgIoClient

  client = newMsgIoClient()
  client.transport = client.newClientTransportTcp(
    # serializer = newSerializerJson()
    serializer = newSerializerMsgPack()
  )

  client.onConnected = proc (client: MsgIoClient): Future[void] {.closure, gcsafe, async.} =
    echo "CLIENT CONNECTED"
    return

  client.onDisconncted = proc (client: MsgIoClient): Future[void] {.closure, gcsafe, async.} =
    echo "CLIENT DISCONNECTED"
    return

  client.onMessage = proc (client: MsgIoClient, msg: MsgBase): Future[void] {.closure, gcsafe, async.} =
    echo $msg
    # await sleepAsync 500
    # await client.send("event", "data")
    # await client.transportSend(client, msg)

  # client.onEvent = proc(client: MsgIoClient, msg: MsgBase): Future[void] {.closure, gcsafe.} =)
  #   echo "CLIENT DISCONNECTED"

  echo waitFor client.connect("127.0.0.1", 9001) # Same as client.onConnect Callback
  waitFor client.send("auth", "password")#
  #waitFor client.send("auth", "data")#
  waitFor client.send("foo", "baa")

  runForever()
  # echo result.payload
