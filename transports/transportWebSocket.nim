import tables, asyncnet, asyncdispatch, asynchttpserver, websocket, future
import ../msgIoServer
import ../types

type
  TransportWs* = object of TransportBase
    clients: ClientsWs
    httpServer: AsyncHttpServer
    address: string
    port: Port
    namespace: string
  ClientsWs = TableRef[ClientId, AsyncSocket]

proc newTransportWs*(namespace = "default", port: int = 9090, address = ""): TransportWs =
  result = TransportWs()
  result.proto = "ws"
  result.address = address
  result.port = port.Port
  result.httpServer = newAsyncHttpServer()
  result.namespace = namespace
  var base = result
  proc sendWs(msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] = 
    echo base.proto
    echo "foo"
  result.send = sendWs
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


proc cb(req: Request, transport: TransportWs) {.async.} =
  let (isWebsocket, websocketError) = await(verifyWebsocketRequest(req, transport.namespace))
  if isWebsocket: 
    # await handleWebsocket(req, wsio)
    echo "is ws"
  else: 
    echo "no http!"

proc serve(transport: TransportWs): Future[void] {.async.} = 
  asyncCheck transport.httpServer.serve(transport.port, (req: Request) => cb(req, transport) )  
  echo "WebsocketIo listens on: ", $transport.port.int

when isMainModule:
  var transportWs = newTransportWs(port=9000)
  asyncCheck transportWs.serve()
  runForever()