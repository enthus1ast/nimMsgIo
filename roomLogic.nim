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
import typesMsgIo


type # Both
  NameSpace* = string # "mandant" rooms with same name could exists on multiple NameSpaces
  RoomId* = string
    
# type NetworkAbstraction* =
#   send
#   recv

type # Server
  # ClientId* = int
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
  Rooms* = TableRef[RoomId, Room]
  RoomLogic* = ref object
    namespace*: NameSpace # the namespace this server is responsible for
    clients*: Clients # all connected clients
    rooms*: Rooms # all created rooms.

proc newClients*(): Clients =
  result = initSet[ClientId]()

proc newRooms*(): Rooms =
  result = newTable[RoomId, Room]()
  
proc newRoomLogic*(namespace: NameSpace = "default"): RoomLogic =
  result = RoomLogic()
  result.namespace = namespace
  result.clients = newClients()
  result.rooms = newRooms()

# proc newClient*(clientId: ClientId = -1): Client =
#   result = Client()
#   result.clientId = clientId
#   # result.

proc newRoom*(roomId: RoomId): Room = 
  result = Room()
  result.roomId = roomId
  result.clients = newClients()

proc joinRoom*(roomLogic: RoomLogic, clientId: ClientId, roomId: RoomId) =
  ## let client join the given room
  ## if room does not exist create it.
  if not roomLogic.rooms.hasKey(roomId):
    roomLogic.rooms[roomId] = newRoom(roomId)
    roomLogic.rooms[roomId].clients.incl(clientId)

proc leaveRoom*(roomLogic: RoomLogic, clientId: ClientId, roomId: RoomId) = 
  ## let client part from the given room
  ## if room is empty afterwards remove it
  if not roomLogic.rooms.hasKey(roomId):
    return
  roomLogic.rooms[roomId].clients.excl(clientId)
  if roomLogic.rooms[roomId].clients.len == 0:
    # if room empty remove close room
    roomLogic.rooms.del(roomId)

proc leaveAllRooms*(roomLogic: RoomLogic, clientId: ClientId) = 
    ## clients leaves all rooms it is connected to.
    for room in roomLogic.rooms.values:
      if room.clients.contains(clientId):
        roomLogic.leaveRoom(clientId, room.roomId) # room.del(client.clientId)
  
# proc sendTo(client: Client) # to spezific client
# proc sendTo(room: Room)   # ro spezific room
# proc broadcast() = discard    # to all connected nodes
# proc disconnect(client: Client) # close connection to given client
# proc disconnect(room: Room)   # close connection to all clients in the this room
# proc dumpTo(client: Client) # dumps every frame to the given client / monitor entire stream
# iterator clients(roomLogic: RoomLogic, room: Room): Client =   
#   ## iterates all clients in a room
#   discard
# iterator clients(roomLogic: RoomLogic): Client = 
#   ## iterates over all clients connected to this server
#   discard

proc clientIdUsed*(roomLogic: RoomLogic, clientId: ClientId): bool =
  return roomLogic.clients.contains(clientId)

proc genClientId*(roomLogic: RoomLogic): ClientId =
  ## generates an unsed client id
  result = -1
  while true:
    result = random( high(int32) )
    if roomLogic.clientIdUsed(result): continue
    else: break

proc connects*(roomLogic: RoomLogic, clientId: ClientId): bool = 
  ## connects a client to the underlying logic
  if roomLogic.clientIdUsed(clientId): return false
  roomLogic.clients.incl(clientId)
  return true

proc disconnects*(roomLogic: RoomLogic, clientId: ClientId) =
  ## disconnects a client from the underlying logic
  if roomLogic.clientIdUsed(clientId):
    roomLogic.leaveAllRooms(clientId)
    roomLogic.clients.excl(clientId)

when isMainModule:
  randomize()
  block: # basic tests
    var roomLogic = newRoomLogic()
    # var tstClient = newClient(roomLogic.genClientId())
    var tstId = roomLogic.genClientId()
    assert tstId != -1
    roomLogic.joinRoom(tstId, "lobby")
    assert roomLogic.rooms.len() == 1
    assert roomLogic.rooms["lobby"].clients.len() == 1
    
    roomLogic.leaveRoom(tstId, "lobby")
    roomLogic.leaveRoom(tstId, "lobby") # leave again
    assert roomLogic.rooms.len() == 0

    roomLogic.joinRoom(tstId, "tst")
    roomLogic.joinRoom(tstId, "tst2")
    assert roomLogic.rooms.len() == 2
    roomLogic.leaveAllRooms(tstId)
    assert roomLogic.rooms.len() == 0

