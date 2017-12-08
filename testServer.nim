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

var onCon = proc (wsio: WebsocketIo, client: Client): Future[void] {.async.} = 
  echo "Client connected, handled in callback:", client.clientId

var onDisCon = proc (wsio: WebsocketIo, client: Client): Future[void] {.async.} = 
  echo "Client DIS connected, handled in callback:", client.clientId

var wsio = newWebsocketIo()
wsio.onClientConnected = onCon 
wsio.onClientDisconnected = onDisCon 
asyncCheck wsio.serveWsIo()
runForever()