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

type # Both
  NameSpace = string # "mandant" rooms with same name could exists on multiple NameSpaces
  RoomId = string
  
type # Server
  OnClientConnected = proc (wsio: WebsocketIo, client: Client): Future[bool] {.closure, gcsafe.}
  OnClientDisconnected = proc (wsio: WebsocketIo, client: Client): Future[void] {.closure, gcsafe.}
  OnClientJoinRoom =  proc (wsio: WebsocketIo, client: Client, room: RoomId): Future[bool] {.closure, gcsafe.}
  OnClientLeaveRoom =  proc (wsio: WebsocketIo, client: Client, room: RoomId): Future[bool] {.closure, gcsafe.}
  Room = object 
    roomId: RoomId
    # roomName: string
    clients: Clients # all joined clients 
  ClientId = int
  Client* = object
    clientId*: ClientId
    websocket: AsyncSocket
  Clients = TableRef[ClientId, Client]
  Rooms = TableRef[RoomId, Room]
  WebsocketIo* = object
    namespace: NameSpace # the namespace this server is responsible for
    clients: Clients # all connected clients
    rooms: Rooms # all created rooms.
    httpServer:  AsyncHttpServer
    onClientConnected*: OnClientConnected 
    onClientDisconnected*: OnClientDisconnected
    onClientJoinRoom*: OnClientJoinRoom
    onClientLeaveRoom*: OnClientLeaveRoom
  
  # Target = int # DUMMY

# type # Client


# client api
proc connect(wsio: WebsocketIo, namespace: NameSpace, uri: string) = 
  discard


# Both
# proc sendText()
# proc sendBinary()

# server

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

proc newClients(): Clients =
  result = newTable[ClientId, Client]()

proc newRooms(): Rooms =
  result = newTable[RoomId, Room]()
  
proc newWebsocketIo*(namespace: NameSpace = "default"): WebsocketIo =
  result = WebsocketIo()
  result.namespace = namespace
  result.clients = newClients()
  result.rooms = newRooms()
  result.httpServer = newAsyncHttpServer()
  result.onClientConnected = nil           ### TODO ?#Option[client.onClientConnected] # none #OnClientConnected]
  result.onClientDisconnected = nil
  result.onClientJoinRoom = nil
  result.onClientLeaveRoom = nil

proc newClient(clientId: ClientId = -1): Client =
  result = Client()
  result.clientId = clientId
  # result.

proc newRoom(roomId: RoomId): Room = 
  result = Room()
  result.roomId = roomId
  result.clients = newClients()

proc joinRoom*(wsio: WebsocketIo, client: Client, roomId: RoomId) =
  ## let client join the given room
  ## if room does not exist create it.
  if not wsio.rooms.hasKey(roomId):
    wsio.rooms[roomId] = newRoom(roomId)
  wsio.rooms[roomId].clients.add(client.clientId, client)
  # wsio.rooms

proc leaveRoom*(wsio: WebsocketIo, client: Client, roomId: RoomId) = 
  ## let client part from the given room
  ## if room is empty afterwards remove it
  if not wsio.rooms.hasKey(roomId):
    return
  wsio.rooms[roomId].clients.del(client.clientId)
  if wsio.rooms[roomId].clients.len == 0:
    # if room empty remove close room
    wsio.rooms.del(roomId)

proc leaveAllRooms*(wsio: WebsocketIo, client: Client) = 
    ## clients leaves all rooms it is connected to.
    for room in wsio.rooms.values:
      if room.clients.hasKey(client.clientId):
        wsio.leaveRoom(client, room.roomId) # room.del(client.clientId)
  
# proc sendTo(client: Client) # to spezific client
# proc sendTo(room: Room)   # ro spezific room
# proc broadcast() = discard    # to all connected nodes
# proc disconnect(client: Client) # close connection to given client
# proc disconnect(room: Room)   # close connection to all clients in the this room
# proc dumpTo(client: Client) # dumps every frame to the given client / monitor entire stream
# iterator clients(wsio: WebsocketIo, room: Room): Client =   
#   ## iterates all clients in a room
#   discard
# iterator clients(wsio: WebsocketIo): Client = 
#   ## iterates over all clients connected to this server
#   discard

proc clientIdUsed(wsio: WebsocketIo, clientId: ClientId): bool =
  return wsio.clients.hasKey(clientId)

proc genClientId(wsio: WebsocketIo): ClientId =
  ## generates an unsed client id
  result = -1
  while true:
    result = random( high(int32) )
    if wsio.clientIdUsed(result): continue
    else: break

proc connects(wsio: WebsocketIo, client: Client): bool = 
  ## connects a client to the underlying logic
  if wsio.clientIdUsed(client.clientId): return false
  wsio.clients.add(client.clientId, client)
  return true

proc disconnects*(wsio: WebsocketIo, client: Client): bool =
  ## disconnects a client from the underlying logic
  if not wsio.clientIdUsed(client.clientId): return false
  client.websocket.close()
  wsio.leaveAllRooms(client)
  wsio.clients.del(client.clientId)
  return true

proc handleMsg(wsio: WebsocketIo, client: Client, rawData: string): Future[void] {.async.} =
  echo "handleMSg"
  discard

proc handleWebsocket(req: Request, wsio: WebsocketIo) {.async.} = 
  echo "New websocket customer arrived!"
  var wsFrame: tuple[opcode: Opcode, data: string]

  # serverState.websockets.add req.client
  var client = newClient( wsio.genClientId() )
  client.websocket = req.client
  if not wsio.connects(client):
    echo "internal logic forbids connection"
    client.websocket.close()
    return

  if not wsio.onClientConnected.isNil:
    if not (await wsio.onClientConnected(wsio, client)):
      echo "user callback forbids connection"
      echo wsio.disconnects(client)
      return


  try:
    await req.client.sendText("HELLO", false)
  except:
    echo getCurrentExceptionMsg()
    return    

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

  # req.client.close()
  # req.client.get
  # serverState.websockets = serverState.websockets.del(req.client)
  if not wsio.onClientDisconnected.isNil:
    await wsio.onClientDisconnected(wsio, client)
  echo "DISCONNECTS RETURNS: ", wsio.disconnects(client)
  echo "Websocket Clients left:", wsio.clients.len()  #serverState.websockets.len()
  echo ".. socket went away." 

proc cb(req: Request, wsio: WebsocketIo) {.async.} =
  let (isWebsocket, websocketError) = await(verifyWebsocketRequest(req, wsio.namespace))
  if isWebsocket: 
    await handleWebsocket(req, wsio)
  else: 
    echo "no http!"
    # await handleHttp(req, serverState)

proc serveWsIo*(wsio: WebsocketIo, port: int = DEFAULT_PORT) {.async.} = 
  asyncCheck wsio.httpServer.serve(port.Port, (req: Request) => cb(req, wsio) )  
  echo "WebsocketIo listens on: ", port

when isMainModule:
  randomize()
  block: # basic tests
    var wsio = newWebsocketIo()
    var tstClient = newClient(wsio.genClientId())
    assert tstClient.clientId != -1
    wsio.joinRoom(tstClient, "lobby")
    assert wsio.rooms.len() == 1
    assert wsio.rooms["lobby"].clients.len() == 1
    
    wsio.leaveRoom(tstClient, "lobby")
    wsio.leaveRoom(tstClient, "lobby") # leave again
    assert wsio.rooms.len() == 0

    wsio.joinRoom(tstClient, "tst")
    wsio.joinRoom(tstClient, "tst2")
    assert wsio.rooms.len() == 2
    wsio.leaveAllRooms(tstClient)
    assert wsio.rooms.len() == 0


  block:

    var counter = 0 # some shared variable # TODO check gcsafety? Maybe make context?

    var onCon = proc (wsio: WebsocketIo, client: Client): Future[bool] {.async,gcsafe.} = 
      echo "Client connected, handled in callback:", client.clientId
      await sleepAsync(1000) # write async code here!
      echo counter
      counter.inc # dummy counter
      wsio.joinRoom(client, "lobby") # on connect we let the client join to a default room

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

# block:
#   wsio.joinRoom(tstClient, "tst")
#   wsio.joinRoom(tstClient, "tst2")
#   await wsio.disconnect(tstClient) 
#   assert wsio.rooms.len() == 0
  # assert wsio.rooms.len() == 0
  # assert wsio.rooms["lobby"].clients.len() == 0 
  
  # echo wsio.rooms
  # asyncCheck wsio.serve()
  # runForever()