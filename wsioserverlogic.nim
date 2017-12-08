#
#
#                   WebsocketIO
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
import tables, asyncnet#, asyncdispatch

# , asynchttpserver, websocket
import random, future, options


type # Both
  NameSpace* = string # "mandant" rooms with same name could exists on multiple NameSpaces
  RoomId* = string
  
# type NetworkAbstraction* =
#   send
#   recv

type # Server
  ClientId* = int
  ClientIds* = seq[ClientId]
  Client*[T] = object
    clientId*: ClientId
    socket* : T
    # websocket*: AsyncSocket
    # custom*: T
  Clients*[T] = TableRef[ClientId, T]
  Room* = object 
    roomId*: RoomId
    clients*: ClientIds # Clients # all joined clients 
    # custom*: T
  Rooms* = TableRef[RoomId, Room]
  WebsocketIoLogic*[T] = object
    namespace*: NameSpace # the namespace this server is responsible for
    clients*: Clients[T] # all connected clients
    rooms*: Rooms # all created rooms.

proc newClients*(): Clients =
  result = newTable[ClientId, Client]()

proc newRooms*(): Rooms =
  result = newTable[RoomId, Room]()
  
proc newWebsocketIoLogic*(namespace: NameSpace = "default"): WebsocketIoLogic =
  result = WebsocketIoLogic()
  result.namespace = namespace
  result.clients = newClients()
  result.rooms = newRooms()
  # result.httpServer = newAsyncHttpServer()
  # result.onClientConnected = nil           ### TODO ?#Option[client.onClientConnected] # none #OnClientConnected]
  # result.onClientDisconnected = nil
  # result.onClientJoinRoom = nil
  # result.onClientLeaveRoom = nil

proc newClient*(clientId: ClientId = -1): Client =
  result = Client()
  result.clientId = clientId
  # result.

proc newRoom*[T](roomId: RoomId): Room = 
  result = Room()
  result.roomId = roomId
  result.clients = newClients()

proc joinRoom*(wsio: WebsocketIoLogic, client: Client, roomId: RoomId) =
  ## let client join the given room
  ## if room does not exist create it.
  if not wsio.rooms.hasKey(roomId):
    wsio.rooms[roomId] = newRoom(roomId)
  wsio.rooms[roomId].clients.add(client.clientId, client)

proc leaveRoom*(wsio: WebsocketIoLogic, client: Client, roomId: RoomId) = 
  ## let client part from the given room
  ## if room is empty afterwards remove it
  if not wsio.rooms.hasKey(roomId):
    return
  wsio.rooms[roomId].clients.del(client.clientId)
  if wsio.rooms[roomId].clients.len == 0:
    # if room empty remove close room
    wsio.rooms.del(roomId)

proc leaveAllRooms*(wsio: WebsocketIoLogic, client: Client) = 
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
# iterator clients(wsio: WebsocketIoLogic, room: Room): Client =   
#   ## iterates all clients in a room
#   discard
# iterator clients(wsio: WebsocketIoLogic): Client = 
#   ## iterates over all clients connected to this server
#   discard

proc clientIdUsed*(wsio: WebsocketIoLogic, clientId: ClientId): bool =
  return wsio.clients.hasKey(clientId)

proc genClientId*(wsio: WebsocketIoLogic): ClientId =
  ## generates an unsed client id
  result = -1
  while true:
    result = random( high(int32) )
    if wsio.clientIdUsed(result): continue
    else: break

proc connects*(wsio: WebsocketIoLogic, client: Client): bool = 
  ## connects a client to the underlying logic
  if wsio.clientIdUsed(client.clientId): return false
  wsio.clients.add(client.clientId, client)
  return true

proc disconnects*(wsio: WebsocketIoLogic, client: Client) =
  ## disconnects a client from the underlying logic
  if wsio.clientIdUsed(client.clientId):
    wsio.leaveAllRooms(client)
    wsio.clients.del(client.clientId)

when isMainModule:
  randomize()
  block: # basic tests
    var wsio = newWebsocketIoLogic()
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

