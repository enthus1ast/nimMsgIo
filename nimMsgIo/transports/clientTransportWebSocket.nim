when not defined(js):
  import asyncnet, asyncdispatch
  import websocket
else:
  import asyncjs
  import karax/jwebsockets
import options
import ../typesSerializer
import ../typesClient


type
  ClientTransportWebSocket* = ref object of ClientTransportBase
    when not defined(js):
      socket*: AsyncSocket
    else:
      socket*: WebSocket

# # proc handleTcp(transport: ClientTransportTcp): Future[void] {.async.} =
# #   while true:
# #     var tcpLineOpt = await transport.socket.recvTransportTcpLine()
# #     if tcpLineOpt.isNone:
# #       await transport.msgIoClient.onDisconncted(transport.msgIoClient)
# #       break
# #     var msgOpt = transport.serializer.unserialize tcpLineOpt.get()
# #     if msgOpt.isNone:
# #       echo "could not unserialize msg disconnecting..."
# #       break
# #     await transport.msgIoClient.onMessage(transport.msgIoClient, msgOpt.get())

when defined(js):
  import options

  type
    Port = int

  proc send*(w: WebSocket; data: string): Future[void] {.async.} =
    w.send(data.cstring)

  # The following connectLowLevel function is only needed,
  # because the newPromise function doesnt support something like newPromise[void],
  # therfore we return an bool, discarding and wrapping it in the connect function
  proc connectLowLevel*(w: var WebSocket; host: string, port: Port): Future[bool] {.async.} =
    w = newWebSocket("ws://" & host & ":" & $port, "default")
    return await newPromise[bool](proc(resolve: proc(response: bool)) =
      w.onopen = proc(e: MessageEvent) =
        resolve(true)
    )
  proc connect*(w: var WebSocket; host: string, port: Port): Future[void] {.async.} =
    discard await w.connectLowLevel(host, port)


proc connectWebSocket(transport: ClientTransportWebSocket, host: string, port: int): Future[bool] {.async.} =
  try:
    await transport.socket.connect(host, port.Port)
  except:
    echo getCurrentExceptionMsg()
    return false
  await transport.socket.send("msgio")
  # asyncCheck transport.msgIoClient.onConnected(transport.msgIoClient)
  # asyncCheck transport.handleTcp()
  return true

# proc sendTcp(transport: ClientTransportTcp, msg: MsgBase): Future[void] {.async.} =
#   var dataOpt: Option[string] = transport.serializer.serialize(msg)
#   if dataOpt.isSome:
#     await transport.socket.send($dataOpt.get().toTransportTcpLine)

# proc newClientTransportTcp*(client: MsgIoClient, serializer: SerializerBase): ClientTransportTcp =
#   result = new ClientTransportTcp
#   result.socket = newAsyncSocket()
#   result.msgIoClient = client
#   result.serializer = serializer
#   var transport = result
#   client.transportConnect = proc (client: MsgIoClient, host: string, port: int): Future[bool] {.closure, gcsafe, async.} =
#     return await transport.connectTcp(host, port)
#   client.transportSend = proc (client: MsgIoClient, msg: MsgBase): Future[void] {.closure, gcsafe, async.} =
#     await transport.sendTcp(msg)

when isMainModule and defined(js):
  var transport = new ClientTransportWebSocket
  discard transport.connectWebSocket("127.0.0.1", 9000)