#
#
#                      msgIo
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
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
import tables, asyncnet, asyncdispatch, future, options, streams, strutils, net, os
# import websocket
import ../msgIoServer
import ../types
import typesTransportTcp

type
  TransportTcp* = ref object of TransportBase
    clients: ClientsTcp
    tcpServer: AsyncSocket
    listenAddress: string
    listenPort: Port
    namespace: string
    msgio: MsgIoServer
    enableSsl: bool 
    sslCertFile: string # enable ssl first
    sslKeyFile: string # enable ssl first
    magicBytes: string # client has to send these directly after connection
    maxMsgLen: int 
    when defined(ssl):
      sslCtx: SSLContext
  ClientsTcpStorage = tuple[socket:AsyncSocket, address: string]
  ClientsTcp = TableRef[ClientId, ClientsTcpStorage ]

proc recvMsgImpl(transport: TransportTcp, client: AsyncSocket): Future[Option[MsgBase]] {.async.} =    
    # read the msg len
    var tcpLineStrOpt = await client.recvTransportTcpLine(transport.maxMsgLen)
    if tcpLineStrOpt.isNone: return
    result = transport.serializer.unserialize(tcpLineStrOpt.get())
    
proc recvMsgImpl(transport: TransportTcp, clientId: ClientId): Future[Option[MsgBase]] =
  if not transport.clients.hasKey clientId: return
  let client = transport.clients[clientId]
  return transport.recvMsgImpl(client.socket)

proc disconnectsImpl(transport: TransportTcp, clientId: ClientId) = 
  var client: ClientsTcpStorage
  if transport.clients.hasKey clientId:
    client = transport.clients[clientId]
    if not client.socket.isClosed:
      client.socket.close()
    transport.clients.del(clientId)

proc onClientConnecting(transport: TransportTcp, address: string, socket: AsyncSocket): Future[void] {.async.} =
  var 
    clientIdOpt = await transport.msgio.onTransportClientConnecting(transport.msgio, transport)
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

  ## trainsport main loop
  while true:
    var msgOpt: Option[MsgBase]
    msgOpt = await transport.recvMsgImpl(socket)
    if msgOpt.isSome:
      await transport.msgio.onClientMsg(transport.msgio, msgOpt.get(), clientId, transport)
    else:
      echo "the msg could not encoded or something else..."
      break
  
  ## Client is gone, delete it from this transport
  transport.disconnectsImpl(clientId)

  ## And inform the msgio server about this loss, so it can react.
  await transport.msgio.onTransportClientDisconnected(transport.msgio, clientId, transport)
    

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
  echo "tcpTransport listens on: ", transport.listenAddress & ":" & $transport.listenPort.int
  transport.tcpServer.bindAddr(Port(transport.listenPort), transport.listenAddress)
  transport.tcpServer.listen()
  while true:
    let (address, socket) = await transport.tcpServer.acceptAddr()
    when defined ssl:
      if transport.enableSsl:
        transport.sslCtx.wrapConnectedSocket(socket, handshakeAsServer)
    echo address
    asyncCheck transport.handleTcp(address, socket)

proc sendTcp(transport: TransportTcp, msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.async.}= 
  var msg = newMsgBase()
  msg.event = event
  msg.payload = data
  # msg.target = $clientId # TODO what is this exactly?
  let msgSerializedOpt = transport.serializer.serialize(msg)
  if msgSerializedOpt.isNone:
    echo "msg could not be serialized"
    return
  let line = msgSerializedOpt.get().toTransportTcpLine()
  await transport.clients[clientId].socket.send($line)

proc newTransportTcp*(msgio: MsgIoServer, serializer: SerializerBase, namespace = "default", port: int = 9001, 
    address = "0.0.0.0", magicBytes = "msgio", maxMsgLen = 64_000, enableSsl = false, sslCertFile = "", sslKeyFile = "", proto = "tcp"): TransportTcp =
  result = TransportTcp()
  result.msgio = msgio
  result.proto = proto
  result.enableSsl = enableSsl
  result.listenAddress = address
  result.listenPort = port.Port
  result.namespace = namespace
  result.magicBytes = magicBytes
  result.serializer = serializer
  result.maxMsgLen = maxMsgLen

  result.tcpServer = newAsyncSocket()
  result.tcpServer.setSockOpt(OptReuseAddr, true)
  when defined ssl:
    if enableSsl:
      if sslCertFile.len == 0 and sslKeyFile.len == 0: 
        raise newException(ValueError, "sslCertFile and sslKeyFile are required when sslEnabled")
      if not (existsFile(sslCertFile) or (existsFile sslKeyFile)):
        raise newException(ValueError, "sslCertFile or sslKeyFile not found!")
      result.sslCtx = newContext(certFile = sslCertFile, keyFile = sslKeyFile)
      result.sslCtx.wrapSocket(result.tcpServer)
  result.clients = newTable[ClientId, ClientsTcpStorage]()
  var transport = result
  result.send = proc(msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.async.} = 
    await sendTcp(transport, msgio, clientId, event, data)
  result.serve = proc (): Future[void] {.async.} = 
    await serveTcp(transport)
  result.recvMsg = proc (clientId: ClientId): Future[Option[MsgBase]] {.async.} = 
    return await recvMsgImpl(transport, clientId)  
  result.disconnects = proc (clientId: ClientId) =
    disconnectsImpl(transport, clientId)

when isMainModule:
  # import ../serializer/serializerMsgPack
  import ../serializer/serializerJson
  var msgio = newMsgIoServer()
  # var transportTcp = msgio.newTransportTcp(serializer = newSerializerMsgPack(), port=9001)
  var transportTcp = msgio.newTransportTcp(serializer = newSerializerJson(), port=9001, 
    enableSsl = true, sslKeyFile = "../ssl/mycert.pem", sslCertFile = "../ssl/mycert.pem" )
  asyncCheck serveTcp(transportTcp)
  runForever()