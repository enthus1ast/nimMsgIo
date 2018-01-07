#
#
#                      msgIo
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## msg io server transport
## for the websocket protocol
import tables, asyncnet, asyncdispatch, asynchttpserver, websocket, future, options
import ../msgIoServer
import ../types

type
  HttpCallback* = proc(transport: TransportBase, msgio: MsgIoServer, req: Request): Future[void]
  TransportWs* = ref object of TransportBase
    clients: ClientsWs
    httpServer: AsyncHttpServer
    address: string
    port: Port
    namespace: string
    msgio: MsgIoServer # parent
    httpCallback*: HttpCallback
  ClientsWs = TableRef[ClientId, AsyncSocket]

proc recvMsgImpl(transport: TransportWs, client: AsyncSocket): Future[Option[MsgBase]] {.async.} =
    try:
      var f = await client.readData(false)
      echo "(opcode: " & $f.opcode & ", data: " & $f.data.len & ")"

      if f.opcode == Opcode.Text:
        result  =  transport.serializer.unserialize( f.data )
    except:
      # echo getCurrentExceptionMsg()
      return

proc recvMsgImpl(transport: TransportWs, clientId: ClientId): Future[Option[MsgBase]] =
  if not transport.clients.hasKey clientId: return
  let client = transport.clients[clientId]
  return transport.recvMsgImpl(client)

proc disconnectsImpl(transport: TransportWs, clientId: ClientId) = 
  var client: AsyncSocket
  if transport.clients.hasKey clientId:
    client = transport.clients[clientId]
    if not client.isClosed:
      client.close()
  transport.clients.del(clientId)


proc onClientConnecting(transport: TransportWs, req: Request): Future[void] {.async.} =
  var 
    clientIdOpt = await transport.msgio.onTransportClientConnecting(transport.msgio, transport)
    clientId: ClientId
  if clientIdOpt.isNone: 
    echo "ServerProgrammer gave the transport no ClientId, so we disconnect the fresh user..."
    req.client.close()
    return
  clientId = clientIdOpt.get()
  transport.clients.add(clientId, req.client)
  assert transport.msgio.onTransportClientConnected.isNil == false
  await transport.msgio.onTransportClientConnected(transport.msgio, clientId, transport)

  ## transport main loop
  while true:
    var msgOpt: Option[MsgBase]
    msgOpt = await transport.recvMsgImpl(req.client)
    if msgOpt.isSome:
      await transport.msgio.onClientMsg(transport.msgio, msgOpt.get(), clientId, transport)
    else:
      echo "the msg could not encoded or something else..."
      break
  
  ## Client is gone, delete it from this transport
  transport.disconnects(clientId)
  # transport.clients.del(clientId)

  ## And inform the msgio server about this loss, so it can react.
  await transport.msgio.onTransportClientDisconnected(transport.msgio, clientId, transport)

proc cb(req: Request, transport: TransportWs): Future[void] {.async.} =
  let (isWebsocket, websocketError) = await(verifyWebsocketRequest(req, transport.namespace))
  if isWebsocket: 
    echo "is ws"
    await onClientConnecting(transport,req)
  else: 
    echo "no http!"
    await transport.httpCallback( transport, transport.msgio, req )

proc serveWebSocket(transport: TransportWs): Future[void] {.async.} = 
  asyncCheck transport.httpServer.serve(transport.port, (req: Request) => cb(req, transport), transport.address )  
  echo "websocketTransport listens on: ", transport.address & ":" & $transport.port.int

proc sendWebSocket(transport: TransportWs, msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.async.}= 
  var msg = newMsgBase()
  msg.event = event
  msg.payload = data
  # msg.target = $clientId # TODO what is this exactly?
  let msgSerializedOpt = transport.serializer.serialize(msg)
  if msgSerializedOpt.isNone: 
    echo "Could not serialize msg"
    return
  try:
    await transport.clients[clientId].sendText(msgSerializedOpt.get(), false)
  except:
    echo "could not send to websocket: ", clientId
    echo getCurrentExceptionMsg()

proc newTransportWs*(msgio: MsgIoServer, namespace = "default", port: int = 9000, 
    address = "0.0.0.0", serializer: SerializerBase, proto = "ws"): TransportWs =
  result = TransportWs()
  result.msgio = msgio
  result.proto = proto
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
  result.recvMsg = proc (clientId: ClientId): Future[Option[MsgBase]] {.async.} = 
    return await recvMsgImpl(transport, clientId)
  result.disconnects = proc (clientId: ClientId) =
    disconnectsImpl(transport, clientId)
  # result.httpCallback 

when isMainModule:
  import ../serializer/serializerMsgPack
  var msgio = newMsgIoServer()
  var transportWs = msgio.newTransportWs(port=9000, serializer = newSerializerMsgPack())
  asyncCheck transportWs.serve()
  runForever()