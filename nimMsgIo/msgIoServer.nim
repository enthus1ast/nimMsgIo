#
#
#                      msgIo
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## The message io "core". This connects all the transports together.
## This also dispatches all messages.
##
## MsgIo can be used to forward messages to different kinds of protocols, 
## such as websocket, tcp, udp. 
## It abstracts the concept of a "room". Clients can belong to multiple groups/rooms, 
## messages to rooms are distributed to all participating clients.

import types, typesShared
import asyncdispatch, options, sequtils, sets
import roomLogic

proc addTransport*(msgio: MsgIoServer, transport: TransportBase) = 
  ## adds a transport to the msg io server.
  ## The transport is responsible for 
  ## 
  ##   - speaking the concrete protocols.
  ##   - Inform the core about connects and disconnects.
  ##
  ## .. code-block::
  ##
  ##    var msgio = newMsgIoServer()
  ##    var wstransport = newTransportWs()
  ##    msgio.addTransport wstransport
  ##    asyncCheck msgio.serve()
  ##    runForever()
  msgio.transports.add transport

proc onTransportClientConnecting*(msgio: MsgIoServer, transport: TransportBase): Future[Option[ClientId]] {.async.} = 
  ## If the option is none, the transport will immediantly disconnect
  ## the client, effectifly refuseing the connection.
  result = some msgio.roomLogic.genClientId()
  if not msgio.onClientConnecting.isNil:
    result = await msgio.onClientConnecting(msgio, result.get(), transport) ## usercallback can change the clientId!

proc onTransportClientConnected(msgio: MsgIoServer, clientId: ClientId, transport: TransportBase): Future[void] {.async.} =
  msgio.clients.add(clientId, transport)
  if not msgio.roomLogic.connects(clientId): return
  if msgio.onClientConnected.isNil:
    echo "server onClientConnected is nil"
  else:
    await msgio.onClientConnected(msgio, clientId, transport)

proc onTransportClientDisconnected(msgio: MsgIoServer, clientId: ClientId, transport: TransportBase): Future[void] {.async.} =
  # TODO should maybe onTransportClientDisconnecting
  # and should call the user supplied onTransportClientDisconneced
  # msgio.onClient

  ## TODO ???
  # We must delete the client after the user callback,
  # cause the user maybe want to use the old client information.
  
  msgio.clients.del(clientId)
  msgio.roomLogic.disconnects(clientId)
  
  if msgio.onClientDisconnected.isNil:
    echo "server onTransportClientDisconnected is nil"
  else:
    await msgio.onClientDisconnected(msgio, clientId, transport)
  
proc newMsgIoServer*(): MsgIoServer = 
  ## The main msg io server
  ## forwards all messages, handles callbacks
  result = MsgIoServer()
  result.transports = @[]
  result.roomLogic = newRoomLogic()
  result.clients = newTable[ClientId, TransportBase]()
  result.onTransportClientConnecting = onTransportClientConnecting # proc (msgio: MsgIoServer): Future[Option[ClientId]] = onTransportClientConnecting(msgio)
  # result.onTransportClientConnected = onTransportClientConnected # proc (msgio: MsgIoServer): Future[Option[ClientId]] = onTransportClientConnecting(msgio)
  result.onTransportClientDisconnected = onTransportClientDisconnected

proc disconnects*(msgio: MsgIoServer, clientId: ClientId): Future[void] {.async.} = 
    ## TODO WHERE TO INFORM ALL OTHER PARTICIPATING CLIENTS ABOUT THIS DISCONNECT?
    ## disconnects a client from the msgIoServer.
    ## client leaves all rooms
    msgio.roomLogic.disconnects(clientId)
    await msgio.clients[clientId].disconnects(clientId)

proc serve*(msgio: MsgIoServer): Future[void] {.async.} =
  for transport in msgio.transports:
    echo transport.proto, " transport loaded"
    asyncCheck transport.serve()

proc pingClients(msgio: MsgIoServer): Future[void] {.async.} =
  ## periodically pings clients
  ## to remove disconnected or very slow clients
  ## this should be completely abstracted from the msgIo user!
  while true:
    echo "pinging clients"
    for clientId, transport in msgio.clients:
      let result = await transport.ping(clientId)
      if result == false:
        # client was unable to fullfill the transports ping
        await msgio.disconnects(clientId)
      else:
        echo "ping:", result, " " ,clientId 
      
proc send(msgio: MsgIoServer, targetClient: ClientId, event, data: string, namespace = DEFAULT_NAMESPACE): Future[void] =
  # TODO transport send needs namespace
  return msgio.clients[targetClient].send(msgio, targetClient, event, data)

proc broadcast(msgio: MsgIoServer, event, data: string, namespace = DEFAULT_NAMESPACE): Future[void] {.async.} =
  ## sends to every connected client on this server
  # TODO transport send needs namespace
  for clientId, transport in msgio.clients.pairs:
    await transport.send(msgio, clientId, event, data)

proc toRoom(msgio: MsgIoServer, roomId: RoomId, event, data: string, namespace = DEFAULT_NAMESPACE): Future[void] {.async.} =
  ## sends to a given room
  # TODO transport send needs namespace
  var nsp = msgio.roomLogic.getNsp(namespace)
  if not nsp.rooms.hasKey(roomId): return
  for clientInRoom in nsp.rooms[roomId].clients.items:
    await msgio.clients[clientInRoom].send(msgio, clientInRoom, event, data) 

proc joinRoom(msgio: MsgIoServer, clientId: ClientId, roomId: RoomId) =
  ## convinient function let clientId join room.
  msgio.roomLogic.joinRoom(clientId, roomId)

proc leaveRoom(msgio: MsgIoServer, clientId: ClientId, roomId: RoomId) =
  ## convinient function let clientId join room.
  msgio.roomLogic.leaveRoom(clientId, roomId)

when isMainModule:
  import strutils
  import transports/transportWebSocket
  import transports/transportTcp
  # import transports/transportUdp
  import serializer/serializerJson
  import serializer/serializerMsgPack
  import asynchttpserver

  var 
    msgio = newMsgIoServer()
    # msgio.registerNamespace("foobaa")
    # var foobaa = msgio.getNamespace("foobaa")
    transWs = msgio.newTransportWs(serializer = newSerializerJson())
    somevar = @["foo", "baa"] # 

    # transTcp = msgio.newTransportTcp(serializer = newSerializerMsgPack())
    transTcpJson = msgio.newTransportTcp(serializer = newSerializerJson())
    transTcpMsgPack = msgio.newTransportTcp(serializer = newSerializerMsgPack(), port = 9003)
    transTcpMsgPackSsl = msgio.newTransportTcp(
      enableSsl = true, 
      serializer = newSerializerMsgPack(), 
      port = 9004,
      sslKeyFile = "ssl/mycert.pem", 
      sslCertFile = "ssl/mycert.pem"      
    )

    # {event: "foo", payload: "payload", target: "target" }
    # transUdp = msgio.newTransportUdp(serializer = newSerializerJson(), port = 9005)
  transWs.httpCallback = proc(transport: TransportBase, msgio: MsgIoServer, req: Request): Future[void] {.async.} =
      ## websocket transport can have a http callback.
      let res = """
        clients: $#
      """ % @[$msgio.clients.len]
      echo somevar
      echo "hello from usersupplied httpCallback"
      await req.respond(Http200, "Hello World; hello from usersupplied httpCallback\n" & res)
  msgio.addTransport(transWs)
  msgio.addTransport(transTcpJson)
  msgio.addTransport(transTcpMsgPack)
  msgio.addTransport(transTcpMsgPackSsl)
  # msgio.addTransport(transUdp)
  msgio.onClientConnecting = proc (msgio: MsgIoServer, clientId: ClientId, transport: TransportBase): Future[Option[ClientID]] {.async.} = #{.closure, gcsafe.} =
    echo "CLIENT CONNECTING IN USER SERVER"
    return some clientId
  msgio.onClientConnected = proc (msgio: MsgIoServer, clientId: ClientId, transport: TransportBase): Future[void] {.async.} = #{.closure, gcsafe.} =
    echo "in user supplied on onClientConnected"
    await msgio.send(clientId, "event", "data")
    await msgio.send(clientId, "event", "hat funktioniert, gä? : )")
    await msgio.send(clientId, "event", "ja! :)")    
    await msgio.broadcast("helloWORLD", "USER: $# connected to this server!" % [$clientId])
    msgio.joinRoom(clientId, "lobby")
    msgio.joinRoom(clientId, transport.proto)
    echo msgio.roomLogic.getNsp().rooms
  msgio.onClientMsg = proc (msgio: MsgIoServer, msg: MsgBase, transport: TransportBase): Future[void] {.async.} = 
    echo "in user supplied onClientMsg"
    echo msg
    case msg.event
    of "tcp":
      await msgio.toRoom("tcp", "msg", msg.payload)
    of "ws":
      await msgio.toRoom("ws", "msgBROWSER", msg.payload)
    else:
      await msgio.toRoom("lobby", "msgBROWSER", msg.payload)
    echo "----"
  msgio.onClientDisconnected = proc (msgio: MsgIoServer, clientId: ClientId, transport: TransportBase): Future[void] {.async.} = 
    echo "in user supplied onClienDisconnect"
    await msgio.broadcast("client disconnected  event", $clientId)
  asyncCheck msgio.serve()
  runForever()

