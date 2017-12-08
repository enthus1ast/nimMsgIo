#
#
#                   WebsocketIO
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
import tables, asyncnet, asyncdispatch, asynchttpserver, websocket
import random, future, options

import wsioserverlogic

const DEFAULT_PORT = 8081
  
type # Server
  OnClientConnected = proc (wsio: WebsocketIo, client: Client): Future[bool] {.closure, gcsafe.}
  OnClientDisconnected = proc (wsio: WebsocketIo, client: Client): Future[void] {.closure, gcsafe.}
  OnClientJoinRoom =  proc (wsio: WebsocketIo, client: Client, room: RoomId): Future[bool] {.closure, gcsafe.}
  OnClientLeaveRoom =  proc (wsio: WebsocketIo, client: Client, room: RoomId): Future[bool] {.closure, gcsafe.}
  WebsocketIo* = object
    logic: WebsocketIoLogic
    httpServer:  AsyncHttpServer
    onClientConnected*: OnClientConnected 
    onClientDisconnected*: OnClientDisconnected
    onClientJoinRoom*: OnClientJoinRoom
    onClientLeaveRoom*: OnClientLeaveRoom

# proc onClientConnected(wsio: WebsocketIo, client: Client): Future[void] {.async.} =
#   # Callback called by the server when a new client connects.
#   discard

# proc onClientDisconnected(wsio: WebsocketIo, client: Client) =
#   # Callback called by the server when a client disconnects.
#   discard

proc onClientMsg(wsio: WebsocketIo, client: Client, target: int) =
  ## Callback called by the server when a client, 
  ## Sends a message.
  discard

proc newWebsocketIo*(namespace: NameSpace = "default"): WebsocketIo =
  result = WebsocketIo()
  result.logic = newWebsocketIoLogic(namespace)
  result.httpServer = newAsyncHttpServer()
  result.onClientConnected = nil           ### TODO ?#Option[client.onClientConnected] # none #OnClientConnected]
  result.onClientDisconnected = nil
  result.onClientJoinRoom = nil
  result.onClientLeaveRoom = nil

proc handleMsg(wsio: WebsocketIo, client: Client, rawData: string): Future[void] {.async.} =
  echo "handleMSg"
  discard

proc handleWebsocket(req: Request, wsio: WebsocketIo) {.async.} = 
  echo "New websocket customer arrived!"
  var wsFrame: tuple[opcode: Opcode, data: string]

  var client = newClient( wsio.logic.genClientId() )
  client.websocket = req.client
  if not wsio.logic.connects(client):
    echo "internal logic forbids connection"
    client.websocket.close()
    return

  if not wsio.onClientConnected.isNil:
    if not (await wsio.onClientConnected(wsio, client)):
      echo "user callback forbids connection"
      echo wsio.logic.disconnects(client)
      client.websocket.close()
      return

  # try:
  #   await req.client.sendText("HELLO", false)
  # except:
  #   echo getCurrentExceptionMsg()
  #   return    

  while true:
    try:
      wsFrame = await req.client.readData(false)
      echo "(opcode: " & $wsFrame.opcode & ", data: " & $wsFrame.data.len & ")"
    except:
      echo getCurrentExceptionMsg()
      break
    
    if wsFrame.data.len == 0: 
      echo "client sends empty message, protocol violation! bye bye!"
      break

    if wsFrame.opcode == Opcode.Binary:
      echo "binary payload not supported, protocol violation! bye bye!"
      break

    if wsFrame.opcode == Opcode.Text:
      await wsio.handleMsg(client, wsFrame.data)
    #   try:
    #     await req.client.sendText("thanks for the data!", false)
    #   except:
    #     echo getCurrentExceptionMsg()
    #     break        

    # else:
    #   try:
    #     await req.client.sendBinary(wsFrame.data, false)
    #   except:
    #     echo getCurrentExceptionMsg()
    #     break   

  if not wsio.onClientDisconnected.isNil:
    await wsio.onClientDisconnected(wsio, client)
  echo "DISCONNECTS RETURNS: ", wsio.logic.disconnects(client)
  echo "Websocket Clients left:", wsio.logic.clients.len()  #serverState.websockets.len()
  echo ".. socket went away." 

proc cb(req: Request, wsio: WebsocketIo) {.async.} =
  let (isWebsocket, websocketError) = await(verifyWebsocketRequest(req, wsio.logic.namespace))
  if isWebsocket: 
    await handleWebsocket(req, wsio)
  else: 
    echo "no http!"
    # await httpCallBack(req: Request, wsio: WebsocketIo)
    # await handleHttp(req, serverState)

proc serveWsIo*(wsio: WebsocketIo, port: int = DEFAULT_PORT) {.async.} = 
  asyncCheck wsio.httpServer.serve(port.Port, (req: Request) => cb(req, wsio) )  
  echo "WebsocketIo listens on: ", port

when isMainModule:
  randomize()

  block:
    var counter = 0 # some shared variable # TODO check gcsafety? Maybe make context?
    
    var onCon = proc (wsio: WebsocketIo, client: Client): Future[bool] {.async,gcsafe.} = 
      echo "Client connected, handled in callback:", client.clientId
      await sleepAsync(1000) # write async code here!
      echo counter
      counter.inc # dummy counter
      wsio.logic.joinRoom(client, "lobby") # on connect we let the client join to a default room
      if true:
        ## If client is allowed by the business logic to connect to the server.
        return true
      else:
        ## If client is NOT allowed by the business logic to connect to the server.
        ## Client gets disconnected automatically after returning false
        return false

    var onDisCon = proc (wsio: WebsocketIo, client: Client): Future[void] {.async,gcsafe.} = 
      echo "Client DIS connected, handled in callback:", client.clientId

    var onJoinRoom = proc (wsio: WebsocketIo, client: Client, room: RoomId): Future[bool] {.async,gcsafe.} = 
      echo "Client onJoinRoom, handled in callback:", client.clientId
      echo "Room:", room

      if true:
        ## If client is allowed by the business logic to join this room.
        return true
      else:
        ## If client is NOT allowed to join the room
        return false

    var onLeaveRoom = proc (wsio: WebsocketIo, client: Client, room: RoomId): Future[bool] {.async,gcsafe.} = 
      echo "Client onLeaveRoom, handled in callback:", client.clientId
      echo "Room:", room

      if true:
        ## If client is allowed by the business logic to join LEAVE this room.
        return true
      else:
        ## If client is NOT allowed to LEAVE the room.
        ## We can forbid clients to leave certain or all rooms!
        ## Then only the server can let clients join/leave rooms
        return false

    var wsio = newWebsocketIo()
    wsio.onClientConnected = onCon 
    wsio.onClientDisconnected = onDisCon 
    wsio.onClientJoinRoom = onJoinRoom
    asyncCheck wsio.serveWsIo()
    runForever()
