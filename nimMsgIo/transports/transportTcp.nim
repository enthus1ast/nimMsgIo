## msg io server transport
## for the tcp protocol
## 
##
## Tcp is a stream, so we have to 
## tell the remote how long the pkg
## is we want to send
## this transport uses the `net` syntax which 
## prefixes every "line/frame/message" with its length
## as an integer
import tables, asyncnet, asyncdispatch, asynchttpserver, future, options
# import websocket
import ../msgIoServer
import ../types

type
  TransportTcp* = ref object of TransportBase
    clients: ClientsTcp
    tcpServer: AsyncSocket
    listenAddress: string
    listenPort: Port
    namespace: string
    msgio: MsgIoServer # parent
    # httpCallback 
  ClientsTcp = TableRef[ClientId, AsyncSocket]

  TransportTcpLine* = object
    size*: uint32
    data*: string

proc onClientConnecting(transport: TransportTcp, req: Request): Future[void] {.async.} =
  var 
    clientIdOpt = await transport.msgio.onTransportClientConnecting(transport.msgio)
    clientId: ClientId
  if clientIdOpt.isNone: 
    echo "User gave the transport no ClientId, so we disconnect the fresh user..."
    req.client.close()
    return
  clientId = clientIdOpt.get()
  transport.clients.add(clientId, req.client)
  await transport.msgio.onTransportClientConnected(transport.msgio, clientId, transport)

proc cb(req: Request, transport: TransportTcp): Future[void] {.async.} =  
  discard

  # let (isWebsocket, websocketError) = await(verifyWebsocketRequest(req, transport.namespace))
  # if isWebsocket: 
  #   echo "is ws"
  #   await onClientConnecting(transport,req)
  # else: 
  #   echo "no http!"

proc servetcp(transport: TransportTcp): Future[void] {.async.} = 
  # asyncCheck transport.tcpServer.serve(transport.port, (req: Request) => cb(req, transport) )  
  echo "tcpTransport listens on: ", $transport.listenPort.int

proc sendTcp(transport: TransportTcp, msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.async.}= 
  # await transport.clients[clientId].sendText(data, false)
  discard

proc newTransportTcp*(msgio: MsgIoServer, namespace = "default", port: int = 9001, address = ""): TransportTcp =
  result = TransportTcp()
  result.msgio = msgio
  result.proto = "tcp"
  result.listenAddress = address
  result.listenPort = port.Port
  result.namespace = namespace
  result.clients = newTable[ClientId, AsyncSocket]()
  var transport = result
  result.send = proc(msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.async.} = 
    # await sendWebSocket(transport, msgio, clientId, event, data)
    discard
  result.serve = proc (): Future[void] {.async.} = 
    discard
    # await serveWebSocket(transport)
  # result.httpCallback 

when isMainModule:
  var msgio = newMsgIoServer()
  var transportTcp = msgio.newTransportTcp(port=9001)
  asyncCheck transportTcp.serve()
  runForever()