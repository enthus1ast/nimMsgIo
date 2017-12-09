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

proc onTransportClientConnected*(msgio: MsgIoServer): Future[Option[ClientId]] {.async.} = 
  ## If the option is none, the transport will immediantly disconnect
  ## the client, effectifly refuseing the connection.
  let clientId = msgio.roomLogic.genClientId()

  if not msgio.onClientConnected.isNil:
    result = await msgio.onClientConnected(msgio, clientId) ## usercallback can change the clientId!
    # if clientIdOpt.isSome: clientId = clientIdOpt.get()
  
  return 

  # ADD TO CLIENT LIST LOGIC

  # proc (msgio: MsgIoServer, clientId: ClientId): Future[bool] = #{.closure, gcsafe.} =

proc newMsgIoServer*(): MsgIoServer = 
  ## The main msg io server
  ## forwards all messages, handles callbacks
  result = MsgIoServer()
  result.transports = @[]
  result.roomLogic = newRoomLogic()
  result.onTransportClientConnected = onTransportClientConnected # proc (msgio: MsgIoServer): Future[Option[ClientId]] = onTransportClientConnected(msgio)

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
  msgio.onClientConnected = proc (msgio: MsgIoServer, clientId: ClientId): Future[Option[ClientID]] {.async.} = #{.closure, gcsafe.} =
    # discard
    echo "CLIENT CONNECTED IN USER SERVER"
    return some(clientId)
    # return
    # await msgio.clients[clientId].send("welcome", "welcome to this server")
    # await msgio.clients[clientId].joinGroup("lobby")
    # await msgio.rooms["lobby"].send("userJoined", clientId)
  asyncCheck msgio.serve()
  assert msgio.transports.len == 1
  echo msgio.transports
  discard msgio.transports[0].send(msgio, 123.ClientId, "event", "data")

  runForever()