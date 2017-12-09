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


proc handleWebsocket(transport: TransportWs, req: Request): Future[void] {.async.} =
  discard
  #  var clientIdOpt = await transport.msgio.onClientConnected(transport.msgio, 0)
  # if transport.msgio.onTransportClientConnected.isNil: 
  #   echo "onTransportClientConnected is nil "
  var 
    clientIdOpt = await transport.msgio.onTransportClientConnecting(transport.msgio, transport)
    clientId: ClientId

  # Checks
  if clientIdOpt.isNone: 
    echo "User gave the transport no ClientId, so we disconnect the fresh user..."
    req.client.close()
    return
  clientId = clientIdOpt.get()
  # if transport.clients.hasKey(clientId):
  #   echo "User gave the transport an existing ClientId, so we disonnect the fresh user..."
  #   return

  transport.clients.add(clientId, req.client)

#  if not connectionAllowed: return
 


proc cb(req: Request, transport: TransportWs): Future[void] {.async.} =
  let (isWebsocket, websocketError) = await(verifyWebsocketRequest(req, transport.namespace))
  if isWebsocket: 
    echo "is ws"
    await handleWebsocket(transport,req)
  else: 
    echo "no http!"

proc serveWebSocket(transport: TransportWs): Future[void] {.async.} = 
  asyncCheck transport.httpServer.serve(transport.port, (req: Request) => cb(req, transport) )  
  echo "websocketTransport listens on: ", $transport.port.int

proc sendWebSocket(transport: TransportWs, msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.async.}= 
  echo transport.proto
  echo "foo"
  await transport.clients[clientId].sendText(data, false)


proc newTransportWs*(msgio: MsgIoServer, namespace = "default", port: int = 9090, address = ""): TransportWs =
  result = TransportWs()
  result.msgio = msgio # ref to base
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
  # var foo = proc (): Future[void] = (): Future[void] => (serveWebSocket(result))
  # result.serve =  proc (): Future[void] -> serveWebSocket(result)  # Future[void] {.closure, gcsafe.} =
    # return serveWebSocket(result)

  # result.serve = proc (): Future[void] {.closure, gcsafe.} =
  #   return serveWebSocket(result)
  # result.serve = serveWebSocket
  # result.httpCallback 


# proc clientConnected() # 

# Wie benutz ichs
# proc recv()
# proc 

# proc send(t: TransportBase) {.async.} = 
#   ## sends to given client
#   discard

# proc send(clientId: ClientId, event, data: string) {.async.} = 
#   ## sends to given client
#   discard

proc disconnect(clientId: ClientId) = 
  ## kill the "connection" of the given client
  discard

proc acceptConnection(): Future[Client] = 
  # Client has connected with this protocol to our transport.
  discard

when isMainModule:
  var msgio = newMsgIoServer()
  var transportWs = msgio.newTransportWs(port=9000)
  asyncCheck transportWs.serve()
  runForever()