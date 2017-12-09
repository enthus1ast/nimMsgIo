#
#
#                   WebsocketIO
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## A little demo server for the WebsocketIo module.

import client
import asyncdispatch


# USER PART ------
var myUsers = initTable[string, User]()

var onCon = proc (msgIo: MsgIo, clientId: ClientId): Future[void] {.async.} = 
  echo "Client connected, handled in callback:", clientId
  await msgIo.clients[clientId].send("msg foo baa")
  await msgIo.broadcast("event", "msg") # to ALL connected clients on this server
  await msgIo.rooms["lobby"].send("event", "msg")

  # send(clientId)
# var onDisCon = proc (wsio: WebsocketIo, client: Client): Future[void] {.async.} = 
#   echo "Client DIS connected, handled in callback:", client.clientId

# ^^^^^^


## Von uns -----------------------------
var wstransport = newWsTransport(namespace="default")
var tcptransport= newTcpTransport(port=8989, interface="0.0.0.0")

var msgio = newMsgIoServer()
msgio.addTransport(wstransport)
msgio.addTransport(tcptransport)
msgio.onClientConnected = onCon 
msgio.onClientDisconnected = onDisCon 
asyncCheck msgio.serve() #serveWsIo()
runForever()