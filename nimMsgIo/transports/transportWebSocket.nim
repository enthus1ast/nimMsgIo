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

  ## transport main loop
  while true:
    var msgOpt: Option[MsgBase]
    try:
      var f = await req.client.readData(false)
      echo "(opcode: " & $f.opcode & ", data: " & $f.data.len & ")"

      if f.opcode == Opcode.Text:
        # EventTransportMsg* = proc (msgio: MsgIoServer, msg, transport: TransportBase): Future[void] {.closure, gcsafe.}  
        try:
          let msg =  transport.serializer.unserialize( f.data )
          # echo msg
          msgOpt = some msg
        except:
          echo getCurrentExceptionMsg()
          echo "could not unserialize message:", f.data
          msgOpt = none MsgBase
        
        # await transport.msgio.onTransportMsg(transport.msgio, clientId, even)
      # if f.opcode == Opcode.Text:
      #   # waitFor req.client.sendText("thanks for the data!", false)
      #   discard
      # else:
      #   # waitFor req.client.sendBinary(f.data, false)
      #   discard

    except:
      echo getCurrentExceptionMsg()
      break  

    if msgOpt.isSome:
      await transport.msgio.onClientMsg(transport.msgio, msgOpt.get(), transport)
    else:
      echo "the msg could not encoded or something else..."

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
  var msg = MsgBase()
  msg.event = event
  msg.payload = data
  msg.target = $clientId # TODO what is this exactly?
  let msgSerialized: string = transport.serializer.serialize(msg)
  await transport.clients[clientId].sendText(msgSerialized, false)

proc newTransportWs*(msgio: MsgIoServer, namespace = "default", port: int = 9000, 
    address = "", serializer: SerializerBase): TransportWs =
  result = TransportWs()
  result.msgio = msgio
  result.proto = "ws"
  result.address = address
  result.port = port.Port
  result.httpServer = newAsyncHttpServer()
  result.namespace = namespace
  result.clients = newTable[ClientId, AsyncSocket]()
  result.serializer = serializer
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