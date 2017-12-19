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

proc onTransportClientConnecting*(msgio: MsgIoServer): Future[Option[ClientId]] {.async.} = 
  ## If the option is none, the transport will immediantly disconnect
  ## the client, effectifly refuseing the connection.
  result = some msgio.roomLogic.genClientId()
  if not msgio.onClientConnecting.isNil:
    result = await msgio.onClientConnecting(msgio, result.get()) ## usercallback can change the clientId!

proc onTransportClientConnected(msgio: MsgIoServer, clientId: ClientId, transport: TransportBase): Future[void] {.async.} =
  msgio.clients.add(clientId, transport)
  await msgio.onClientConnected(msgio, clientId)

proc newMsgIoServer*(): MsgIoServer = 
  ## The main msg io server
  ## forwards all messages, handles callbacks
  result = MsgIoServer()
  result.transports = @[]
  result.roomLogic = newRoomLogic()
  result.clients = newTable[ClientId, TransportBase]()
  result.onTransportClientConnecting = onTransportClientConnecting # proc (msgio: MsgIoServer): Future[Option[ClientId]] = onTransportClientConnecting(msgio)
  result.onTransportClientConnected = onTransportClientConnected # proc (msgio: MsgIoServer): Future[Option[ClientId]] = onTransportClientConnecting(msgio)

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
    echo "CLIENT CONNECTING IN USER SERVER"
    return some clientId
  msgio.onClientConnected = proc (msgio: MsgIoServer, clientId: ClientId): Future[void] {.async.} = #{.closure, gcsafe.} =
    echo "in user supplied on onClientConnected"
    await msgio.clients[clientId].send(msgio, clientId, "event", "data")
    await msgio.clients[clientId].send(msgio, clientId, "event", "hat funktioniert, gä? : )")
    await msgio.clients[clientId].send(msgio, clientId, "event", "ja! :)")
  asyncCheck msgio.serve()
  assert msgio.transports.len == 1
  runForever()