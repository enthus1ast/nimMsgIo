## msg io server transport
## for the websocket protocol
import tables, asyncnet, asyncdispatch, asynchttpserver, websocket, future, options
import ../msgIoServer
import ../types

type
  TransportWs* = ref object of TransportBase
    clients: ClientsWs
    httpServer: AsyncHttpServer
    address: string
    port: Port
    namespace: string
    msgio: MsgIoServer # parent
    # httpCallback 
  ClientsWs = TableRef[ClientId, AsyncSocket]

proc onClientConnecting(transport: TransportWs, req: Request): Future[void] {.async.} =
  var 
    clientIdOpt = await transport.msgio.onTransportClientConnecting(transport.msgio)
    clientId: ClientId
  if clientIdOpt.isNone: 
    echo "ServerProgrammer gave the transport no ClientId, so we disconnect the fresh user..."
    req.client.close()
    return
  clientId = clientIdOpt.get()
  transport.clients.add(clientId, req.client)
  await transport.msgio.onTransportClientConnected(transport.msgio, clientId, transport)

proc cb(req: Request, transport: TransportWs): Future[void] {.async.} =
  let (isWebsocket, websocketError) = await(verifyWebsocketRequest(req, transport.namespace))
  if isWebsocket: 
    echo "is ws"
    await onClientConnecting(transport,req)
  else: 
    echo "no http!"

proc serveWebSocket(transport: TransportWs): Future[void] {.async.} = 
  asyncCheck transport.httpServer.serve(transport.port, (req: Request) => cb(req, transport) )  
  echo "websocketTransport listens on: ", $transport.port.int

proc sendWebSocket(transport: TransportWs, msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.async.}= 
  await transport.clients[clientId].sendText(data, false)

proc newTransportWs*(msgio: MsgIoServer, namespace = "default", port: int = 9000, address = ""): TransportWs =
  result = TransportWs()
  result.msgio = msgio
  result.proto = "ws"
  result.address = address
  result.port = port.Port
  result.httpServer = newAsyncHttpServer()
  result.namespace = namespace
  result.clients = newTable[ClientId, AsyncSocket]()
  var transport = result
  result.send = proc(msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.async.} = 
    await sendWebSocket(transport, msgio, clientId, event, data)
  result.serve = proc (): Future[void] {.async.} = 
    await serveWebSocket(transport)
  # result.httpCallback 

when isMainModule:
  var msgio = newMsgIoServer()
  var transportWs = msgio.newTransportWs(port=9000)
  asyncCheck transportWs.serve()
  runForever()