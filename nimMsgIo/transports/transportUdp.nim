#
#
#                      msgIo
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## msg io server transport
## for the udp protocol
## 
##
import tables, net, asyncnet, asyncdispatch, future, options, 
  streams, strutils, nativesockets, sets
# import websocket
import ../msgIoServer
import ../types

# import typesTransportUdp

type
  TransportUdp* = ref object of TransportBase
    clients: ClientsUdp
    clientsAddresses: Table[(string, Port), ClientId] #if not (address, port) in transports.clientsAddress:
    udpServer: AsyncSocket
    listenAddress: string
    listenPort: Port
    namespace: string
    msgio: MsgIoServer
    # enableSsl: bool ## TODO
    magicBytes: string # client has to send these directly after connection
    maxMsgLen: int 

  ClientsUdpStorage = tuple[host: string, port: Port, lastMsg: float]
  ClientsUdp = TableRef[ClientId, ClientsUdpStorage ]

proc onClientConnecting(transport: TransportUdp, address: string, socket: Socket): Future[void] {.async.} =
  var 
    clientIdOpt = await transport.msgio.onTransportClientConnecting(transport.msgio, transport)
    clientId: ClientId
  if clientIdOpt.isNone: 
    echo "ServerProgrammer gave the transport no ClientId, so we disconnect the fresh user..."
    # socket.close()
    return
  clientId = clientIdOpt.get()
  var clientStorage: ClientsUdpStorage
  # clientStorage.address = address
  # clientStorage.socket = socket
  transport.clients.add(clientId, clientStorage)
  await transport.msgio.onTransportClientConnected(transport.msgio, clientId, transport)

  ## trainsport main loop
  while true:
    var msgOpt: Option[MsgBase]
    var buffer: string 
    var msgLen: int
    
    # read the msg len
    # try:
    #   buffer = await socket.recv( sizeof(uint32) )
    # except:
    #   echo getCurrentExceptionMsg()
    #   break
    if buffer.len == 0: break
    var msgLenStr = newStringStream( buffer )

    try:
      msgLen = msgLenStr.readUint32().int
    except:
      echo getCurrentExceptionMsg()
      echo "could not read int from msgLenStr"
      break

    if msgLen > transport.maxMsgLen: 
      echo "msg to large!: ", msgLen
      break

    # read the payload message
    # try:
    #   buffer = await socket.recv( msgLen )
    # except:
    #   echo getCurrentExceptionMsg()
    #   break
    if buffer.len == 0: break
    # let msgStr = buffer

    msgOpt = transport.serializer.unserialize(buffer)
    
    if msgOpt.isSome:
      await transport.msgio.onClientMsg(transport.msgio, msgOpt.get(), transport)
    else:
      echo "the msg could not encoded or something else..."
  
  ## Client is gone, delete it from this transport
  socket.close()
  transport.clients.del(clientId)

  ## And inform the msgio server about this loss, so it can react.
  await transport.msgio.onTransportClientDisconnected(transport.msgio, clientId, transport)
    

# proc handle(transport: TransportUdp, address: string, socket: Socket): Future[void] {.async.} = 
#   # Check for magic bytes, to fail fast for non msgIo clients!
#   if not transport.magicBytes.isNil:
#     # let clientMagicBytes = await socket.recv( transport.magicBytes.len )
#     # if clientMagicBytes != transport.magicBytes:
#     #   echo "incorrect magic bytes, got:", clientMagicBytes
#     #   socket.close
#       return
#   asyncCheck onClientConnecting(transport, address, socket)

proc serveUdp(transport: TransportUdp): Future[void] {.async.} = 
  echo "udpTransport listens on: ", $transport.listenPort.int
  transport.udpServer.bindAddr(transport.listenPort)
  var data = ""
  var address = ""
  var port: Port
  var clientIdOpt: Option[ClientId]
  while true:
    try:
      let size = transport.udpServer.recvFrom(data, transport.maxMsgLen, address, port )
      echo ">: ", size , " ", address,":", port, " " , data
      # gotMessage = true
    except:
      continue

    let msgOpt = transport.serializer.unserialize(data)
    if msgOpt.isNone: 
      echo "Could not unserialize msg"
      echo getCurrentExceptionMsg()
      continue
    let msg = msgOpt.get()
    
    if not ((address, port) in transport.clientsAddresses):
      echo "new connection"
      clientIdOpt = await transport.msgio.onTransportClientConnecting(transport.msgio, transport)
      if clientIdOpt.isSome:
        transport.clientsAddresses.add( (address, port), clientIdOpt.get())
        # EventTransportClientConnected* = proc (msgio: MsgIoServer, clientId: ClientId, transport: TransportBase): Future[void] {.closure, gcsafe.}  
        await transport.msgio.onTransportClientConnected(transport.msgio, clientIdOpt.get(), transport)
    else:
      echo "old connection"
      # if transport.clientsAddresses.contains()
      
    await sleepAsync(500) # to let other tasks run # TODO

    # let (address, socket) = await transport.udpServer. #.acceptAddr()
    # echo address
    # # asyncCheck transport.handleTcp(address, socket)

proc sendUdp(transport: TransportUdp, msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.async.}= 
  var msg = MsgBase()
  msg.event = event
  msg.payload = data
  msg.target = $clientId # TODO what is this exactly?
  let msgSerializedOpt = transport.serializer.serialize(msg)
  if msgSerializedOpt.isNone:
    echo "msg could not be serialized"
    return
  # let line = msgSerializedOpt.get().toTransportUdpLine()
  # await transport.clients[clientId].socket.send($line)
  var remoteClient = transport.clients[clientId]
  
  let sentBytes = transport.udpServer.sendTo(remoteClient.host, remoteClient.port, msgSerializedOpt.get())
  echo sentBytes

proc newTransportUdp*(msgio: MsgIoServer, serializer: SerializerBase, namespace = "default", port: int = 9001, 
    address = "", magicBytes = "msgio", maxMsgLen = 64_000): TransportUdp =
  result = TransportUdp()
  result.msgio = msgio
  result.proto = "udp-unreliable"
  result.listenAddress = address
  result.listenPort = port.Port
  result.namespace = namespace
  result.magicBytes = magicBytes
  result.serializer = serializer
  result.maxMsgLen = maxMsgLen
  result.clientsAddresses = initTable[(string, Port), ClientId]()

  # result.tcpServer = newAsyncSocket()
  # result.udpServer = newAsyncSocket()
  # result.udpServer.setSockOpt(OptReuseAddr, true)
  result.udpServer = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  result.udpServer.setSockOpt(OptReuseAddr, true)
  result.udpServer.getFd().setBlocking(false)
  

  result.clients = newTable[ClientId, ClientsUdpStorage]()
  var transport = result
  result.send = proc(msgio: MsgIoServer, clientId: ClientId, event, data: string): Future[void] {.async.} = 
    await sendUdp(transport, msgio, clientId, event, data)
  result.serve = proc (): Future[void] {.async.} = 
    await serveUdp(transport)

when isMainModule:
  # import ../serializer/serializerMsgPack
  import ../serializer/serializerJson
  var msgio = newMsgIoServer()
  # var transportUdp = msgio.newTransportUdp(serializer = newSerializerMsgPack(), port=9001)
  var transportUdp = msgio.newTransportUdp(serializer = newSerializerJson(), port=9009)
  asyncCheck serveUdp(transportUdp)
  runForever()