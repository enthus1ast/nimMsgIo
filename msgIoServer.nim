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


import types
import asyncdispatch
import sequtils

proc newMsgIoServer*(): MsgIoServer = 
  ## The main msg io server
  ## forwards all messages, handles callbacks

  result = MsgIoServer()
  result.transports = @[]

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

proc serve*(msgio: MsgIoServer): Future[void] {.async.} =
  for transport in msgio.transports:
    echo transport.proto, " transport loaded"
    asyncCheck transport.serve()


when isMainModule:
  import transports/transportWebSocket
  var 
    transportWs = newTransportWs()
    msgio = newMsgIoServer()
  msgio.addTransport(transportWs)
  msgio.onClientConnected = proc (msgio: MsgIoServer, clientId: ClientId): Future[bool] = #{.closure, gcsafe.} =
    discard
    # await msgio.clients[clientId].send("welcome", "welcome to this server")
    # await msgio.clients[clientId].joinGroup("lobby")
    # await msgio.rooms["lobby"].send("userJoined", clientId)
  asyncCheck msgio.serve()
  assert msgio.transports.len == 1
  echo msgio.transports
  discard msgio.transports[0].send(msgio, 123.ClientId, "event", "data")

  runForever()