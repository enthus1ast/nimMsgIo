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
  if msgio.onClientConnected.isNil:
    echo "server onClientConnected is nil"
  else:
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
      
proc send(msgio: MsgIoServer, targetClient: ClientId, event, data: string): Future[void] =
  return msgio.clients[targetClient].send(msgio, targetClient, event, data)

when isMainModule:
  import transports/transportWebSocket
  import transports/transportTcp
  import serializer/serializerJson
  import serializer/serializerMsgPack

  var 
    msgio = newMsgIoServer()
    transWs = msgio.newTransportWs(serializer = newSerializerJson())
    # transTcp = msgio.newTransportTcp(serializer = newSerializerMsgPack())
    transTcp = msgio.newTransportTcp(serializer = newSerializerJson())
  msgio.addTransport(transWs)
  msgio.addTransport(transTcp)
  msgio.onClientConnecting = proc (msgio: MsgIoServer, clientId: ClientId): Future[Option[ClientID]] {.async.} = #{.closure, gcsafe.} =
    echo "CLIENT CONNECTING IN USER SERVER"
    return some clientId
  msgio.onClientConnected = proc (msgio: MsgIoServer, clientId: ClientId): Future[void] {.async.} = #{.closure, gcsafe.} =
    echo "in user supplied on onClientConnected"
    await msgio.send(clientId, "event", "data")
    await msgio.send(clientId, "event", "hat funktioniert, gä? : )")
    await msgio.send(clientId, "event", "ja! :)")    
  # msgio.onC
  asyncCheck msgio.serve()
  assert msgio.transports.len == 2
  runForever()

