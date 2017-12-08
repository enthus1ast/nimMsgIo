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
import sets


type # Both
  NameSpace* = string # "mandant" rooms with same name could exists on multiple NameSpaces
  RoomId* = string
  
# type NetworkAbstraction* =
#   send
#   recv

type # Server
  ClientId* = int
  # ClientIds* = seq[ClientId]
  # Client*[T] = object
  #   clientId*: ClientId
  #   socket* : T
    # websocket*: AsyncSocket
    # custom*: T
  Clients* =  HashSet[ClientId] #TableRef[ClientId, T]
  Room* = object 
    roomId*: RoomId
    clients*: Clients # Clients # all joined clients 
    # custom*: T
  Rooms* = TableRef[RoomId, Room]
  WebsocketIoLogic* = ref object
    namespace*: NameSpace # the namespace this server is responsible for
    clients*: Clients # all connected clients
    rooms*: Rooms # all created rooms.

proc newClients*(): Clients =
  # result = newTable[ClientId, Client]()
  result = initSet[ClientId]()

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

# proc newClient*(clientId: ClientId = -1): Client =
#   result = Client()
#   result.clientId = clientId
#   # result.

proc newRoom*(roomId: RoomId): Room = 
  result = Room()
  result.roomId = roomId
  result.clients = newClients()

proc joinRoom*(wsio: WebsocketIoLogic, clientId: ClientId, roomId: RoomId) =
  ## let client join the given room
  ## if room does not exist create it.
  if not wsio.rooms.hasKey(roomId):
    wsio.rooms[roomId] = newRoom(roomId)
    wsio.rooms[roomId].clients.incl(clientId)
  # wsio.rooms[roomId].clients.add(client.clientId, client)
  # wsio.rooms[roomId].clients.add(client.clientId, client)

proc leaveRoom*(wsio: WebsocketIoLogic, clientId: ClientId, roomId: RoomId) = 
  ## let client part from the given room
  ## if room is empty afterwards remove it
  if not wsio.rooms.hasKey(roomId):
    return
  wsio.rooms[roomId].clients.excl(clientId)
  if wsio.rooms[roomId].clients.len == 0:
    # if room empty remove close room
    wsio.rooms.del(roomId)

proc leaveAllRooms*(wsio: WebsocketIoLogic, clientId: ClientId) = 
    ## clients leaves all rooms it is connected to.
    for room in wsio.rooms.values:
      if room.clients.contains(clientId):
        wsio.leaveRoom(clientId, room.roomId) # room.del(client.clientId)
  
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
  return wsio.clients.contains(clientId)

proc genClientId*(wsio: WebsocketIoLogic): ClientId =
  ## generates an unsed client id
  result = -1
  while true:
    result = random( high(int32) )
    if wsio.clientIdUsed(result): continue
    else: break

proc connects*(wsio: WebsocketIoLogic, clientId: ClientId): bool = 
  ## connects a client to the underlying logic
  if wsio.clientIdUsed(clientId): return false
  wsio.clients.incl(clientId)
  return true

proc disconnects*(wsio: WebsocketIoLogic, clientId: ClientId) =
  ## disconnects a client from the underlying logic
  if wsio.clientIdUsed(clientId):
    wsio.leaveAllRooms(clientId)
    wsio.clients.excl(clientId)

when isMainModule:
  randomize()
  block: # basic tests
    var wsio = newWebsocketIoLogic()
    # var tstClient = newClient(wsio.genClientId())
    var tstId = wsio.genClientId()
    assert tstId != -1
    wsio.joinRoom(tstId, "lobby")
    assert wsio.rooms.len() == 1
    assert wsio.rooms["lobby"].clients.len() == 1
    
    wsio.leaveRoom(tstId, "lobby")
    wsio.leaveRoom(tstId, "lobby") # leave again
    assert wsio.rooms.len() == 0

    wsio.joinRoom(tstId, "tst")
    wsio.joinRoom(tstId, "tst2")
    assert wsio.rooms.len() == 2
    wsio.leaveAllRooms(tstId)
    assert wsio.rooms.len() == 0

