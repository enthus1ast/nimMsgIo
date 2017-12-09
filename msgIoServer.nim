#
#
#                   WebsocketIO
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
import asyncdispatch, options, sequtils
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
  var clientId = msgio.roomLogic.genClientId()

  if not msgio.onClientConnecting.isNil:
    result = await msgio.onClientConnecting(msgio, clientId) ## usercallback can change the clientId!
  
  if result.isNone:
    return
  
  clientId = result.get()
  # echo "Transport: ", repr transport
  msgio.clients.add(clientId, transport)
    # if clientIdOpt.isSome: clientId = clientIdOpt.get()
  # echo repr msgio.onClientConnected
  # echo repr msgio
  # echo repr clientId
  if msgio.onClientConnected.isNil: 
    echo "msgio.onClientConnected.isNil"
    return
  await msgio.onClientConnected(msgio, clientId) ## usercallback can change the clientId!
  
  # ADD TO CLIENT LIST LOGIC

  # proc (msgio: MsgIoServer, clientId: ClientId): Future[bool] = #{.closure, gcsafe.} =

proc newMsgIoServer*(): MsgIoServer = 
  ## The main msg io server
  ## forwards all messages, handles callbacks
  result = MsgIoServer()
  result.transports = @[]
  result.roomLogic = newRoomLogic()
  result.clients = newTable[ClientId, TransportBase]()
  result.onTransportClientConnecting = onTransportClientConnecting # proc (msgio: MsgIoServer): Future[Option[ClientId]] = onTransportClientConnecting(msgio)


proc serve*(msgio: MsgIoServer): Future[void] {.async.} =
  for transport in msgio.transports:
    echo transport.proto, " transport loaded"
    asyncCheck transport.serve()

when isMainModule:
  import transports/transportWebSocket
  var 
    msgio = newMsgIoServer()
    transportWs = msgio.newTransportWs()
  msgio.addTransport(transportWs)
  msgio.onClientConnecting = proc (msgio: MsgIoServer, clientId: ClientId): Future[Option[ClientID]] {.async.} = #{.closure, gcsafe.} =
    # discard
    echo "CLIENT CONNECTING IN USER SERVER"
    # echo msgio.transports[0]
    # await  msgio.transports[0].send(msgio, 123.ClientId, "event", "data")
    echo "$clientId: ", $clientId
    return some(clientId)
    # return
    # await msgio.clients[clientId].send("welcome", "welcome to this server")
    # await msgio.clients[clientId].joinGroup("lobby")
    # await msgio.rooms["lobby"].send("userJoined", clientId)
  msgio.onClientConnected = proc (msgio: MsgIoServer, clientId: ClientId): Future[void] {.async.} = #{.closure, gcsafe.} =
    echo "in user supplied on onClientConnected"
    # await sleepAsync(1000)
    echo msgio.clients.hasKey(clientId)
    # echo repr msgio.clients[clientId]
    await msgio.clients[clientId].send(msgio, clientId, "event", "data")

  asyncCheck msgio.serve()
  assert msgio.transports.len == 1
  # echo msgio.transports
  # discard msgio.transports[0].send( 123.ClientId, "event", "data")

  runForever()