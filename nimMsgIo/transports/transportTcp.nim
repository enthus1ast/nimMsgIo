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
import tables, asyncnet, asyncdispatch, future, options
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
    enableSsl: bool ## TODO
    magicBytes: string # client has to send these directly after connection
    # httpCallback 
  ClientsTcpStorage = tuple[socket:AsyncSocket, address: string]
  ClientsTcp = TableRef[ClientId, ClientsTcpStorage ]

  TransportTcpLine* = object
    size*: uint32
    data*: string

# proc onClientConnecting(transport: TransportTcp, req: Request): Future[void] {.async.} =
#   var 
#     clientIdOpt = await transport.msgio.onTransportClientConnecting(transport.msgio)
#     clientId: ClientId
#   if clientIdOpt.isNone: 
#     echo "User gave the transport no ClientId, so we disconnect the fresh user..."
#     req.client.close()
#     return
#   clientId = clientIdOpt.get()
#   transport.clients.add(clientId, req.client)
#   await transport.msgio.onTransportClientConnected(transport.msgio, clientId, transport)

# proc cb(req: Request, transport: TransportTcp): Future[void] {.async.} =  
#   discard

  # let (isWebsocket, websocketError) = await(verifyWebsocketRequest(req, transport.namespace))
  # if isWebsocket: 
  #   echo "is ws"
  #   await onClientConnecting(transport,req)
  # else: 
  #   echo "no http!"

proc onClientConnecting(transport: TransportTcp, address: string, socket: AsyncSocket): Future[void] {.async.} =
  var 
    clientIdOpt = await transport.msgio.onTransportClientConnecting(transport.msgio)
    clientId: ClientId
  if clientIdOpt.isNone: 
    echo "ServerProgrammer gave the transport no ClientId, so we disconnect the fresh user..."
    socket.close()
    return
  clientId = clientIdOpt.get()
  var clientStorage: ClientsTcpStorage
  clientStorage.address = address
  clientStorage.socket = socket
  transport.clients.add(clientId, clientStorage)
  await transport.msgio.onTransportClientConnected(transport.msgio, clientId, transport)


proc handleTcp(transport: TransportTcp, address: string, socket: AsyncSocket): Future[void] {.async.} = 
    # Check for magic bytes, to fail fast for non msgIo clients!
    if not transport.magicBytes.isNil:
      let clientMagicBytes = await socket.recv( transport.magicBytes.len )
      if clientMagicBytes != transport.magicBytes:
        echo "incorrect magic bytes, got:", clientMagicBytes
        socket.close
        return
    asyncCheck onClientConnecting(transport, address, socket)

proc serveTcp(transport: TransportTcp): Future[void] {.async.} = 
  # asyncCheck transport.tcpServer.serve(transport.port, (req: Request) => cb(req, transport) )  
  ## Binds to address, starts listening on transport port
  ## starts the main transport message loop
  # echo "Transport started"
  echo "tcpTransport listens on: ", $transport.listenPort.int
  transport.tcpServer.bindAddr(Port(transport.listenPort))
  transport.tcpServer.listen()
  while true:
    echo "tcp."
    let (address, socket) = await transport.tcpServer.acceptAddr()
    echo address
    asyncCheck transport.handleTcp(address, socket)


 

proc sendTcp(transport: TransportTcp, msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.async.}= 
  # await transport.clients[clientId].sendText(data, false)
  echo "would send to tcp"
  # await transport.clients[clientId].sendText(data, false)
  await transport.clients[clientId].socket.send(data)
  discard




proc newTransportTcp*(msgio: MsgIoServer, namespace = "default", port: int = 9001, 
    address = "", enableSsl = false, magicBytes = "msgio"): TransportTcp =
  result = TransportTcp()
  result.msgio = msgio
  result.proto = "tcp"
  result.enableSsl = enableSsl
  result.listenAddress = address
  result.listenPort = port.Port
  result.namespace = namespace
  result.magicBytes = magicBytes

  result.tcpServer = newAsyncSocket()
  result.tcpServer.setSockOpt(OptReuseAddr, true)

  result.clients = newTable[ClientId, ClientsTcpStorage]()
  var transport = result
  result.send = proc(msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.async.} = 
    # await sendWebSocket(transport, msgio, clientId, event, data)
    await sendTcp(transport, msgio, clientId, event, data)
  result.serve = proc (): Future[void] {.async.} = 
    # discard
    await serveTcp(transport)
  # result.httpCallback 

when isMainModule:
  var msgio = newMsgIoServer()
  var transportTcp = msgio.newTransportTcp(port=9001)
  asyncCheck serveTcp(transportTcp)
  runForever()