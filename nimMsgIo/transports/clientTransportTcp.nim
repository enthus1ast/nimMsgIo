import asyncnet, asyncdispatch, options
import ../typesSerializer
import ../typesClient
import typesTransportTcp


type
  ClientTransportTcp* = ref object of ClientTransportBase
    socket*: AsyncSocket

proc handleTcp(transport: ClientTransportTcp): Future[void] {.async.} =
  while true:
    var tcpLineOpt = await transport.socket.recvTransportTcpLine()
    if tcpLineOpt.isNone:
      await transport.msgIoClient.onDisconncted(transport.msgIoClient)
      break
    var msgOpt = transport.serializer.unserialize tcpLineOpt.get()
    if msgOpt.isNone: 
      echo "could not unserialize msg disconnecting..."
      break
    await transport.msgIoClient.onMessage(transport.msgIoClient, msgOpt.get())

proc connectTcp(transport: ClientTransportTcp, host: string, port: int): Future[bool] {.async.} =
  try:
    await transport.socket.connect(host, port.Port)
  except:
    echo getCurrentExceptionMsg()
    return false
  await transport.socket.send("msgio")
  asyncCheck transport.msgIoClient.onConnected(transport.msgIoClient)
  asyncCheck transport.handleTcp()
  return true

proc newClientTransportTcp*(client: MsgIoClient, serializer: SerializerBase): ClientTransportTcp =
  result = new ClientTransportTcp
  result.socket = newAsyncSocket()
  result.msgIoClient = client
  result.serializer = serializer
  var transport = result
  client.transportConnect = proc (client: MsgIoClient, host: string, port: int): Future[bool] {.closure, gcsafe, async.} =
    return await transport.connectTcp(host, port)