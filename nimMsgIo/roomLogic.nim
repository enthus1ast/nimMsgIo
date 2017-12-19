#
#
#                   WebsocketIO
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
import tables, asyncnet

import random, future, options
import sets
import typesRoomLogic
export typesRoomLogic

proc newClients*(): Clients =
  result = initSet[ClientId]()

proc newRooms*(): Rooms =
  result = newTable[RoomId, Room]()
  
proc newRoomLogic*(namespace: NameSpace = "default"): RoomLogic =
  randomize()
  result = RoomLogic()
  result.namespace = namespace
  result.clients = newClients()
  result.rooms = newRooms()

proc newRoom*(roomId: RoomId): Room = 
  result = Room()
  result.roomId = roomId
  result.clients = newClients()

proc joinRoom*(roomLogic: RoomLogic, clientId: ClientId, roomId: RoomId) =
  ## let client join the given room
  ## if room does not exist create it.
  if not roomLogic.clients.contains clientId:
    echo "connect client first!:", clientId
    return
  if not roomLogic.rooms.hasKey(roomId):
    roomLogic.rooms[roomId] = newRoom(roomId)
  roomLogic.rooms[roomId].clients.incl(clientId)

proc leaveRoom*(roomLogic: RoomLogic, clientId: ClientId, roomId: RoomId) = 
  ## let client part from the given room
  ## if room is empty afterwards remove it
  if not roomLogic.clients.contains clientId:
    echo "connect client first!:", clientId
    return  
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
  
proc getParticipatingClients*(roomLogic: RoomLogic, clientId: ClientId): HashSet[ClientId] =
  ## returns a set with all clientId's the given clientId is in contact with
  result = initSet[ClientId]()
  for room in roomLogic.rooms.values:
    echo room
    if room.clients.contains clientId:
      for roomParticipant in room.clients:
        if clientId != roomParticipant: # filter out ourselv
          result.incl roomParticipant

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
  var dummyRoomLogic = newRoomLogic()
  var tstId1 = dummyRoomLogic.genClientId()
  var tstId2 = dummyRoomLogic.genClientId()
  var tstId3 = dummyRoomLogic.genClientId()
  assert tstId1 != tstId2 

  block: # basic tests
    var roomLogic = newRoomLogic()
    # var tstClient = newClient(roomLogic.genClientId())
    var tstId = roomLogic.genClientId()
    assert tstId != -1
    assert true == roomLogic.connects(tstId)
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

  block:
    var roomLogic = newRoomLogic()
    assert true == roomLogic.connects tstId1
    roomLogic.joinRoom(tstId1, "lobby")
    assert roomLogic.rooms.hasKey("lobby")
    roomLogic.disconnects(tstId1)
    assert false == roomLogic.rooms.hasKey("lobby")

  block:
    var roomLogic = newRoomLogic()
    assert true == roomLogic.connects tstId1
    assert true == roomLogic.connects tstId2
    assert true == roomLogic.clients.contains(tstId1)
    assert true == roomLogic.clients.contains(tstId2)
    
    roomLogic.joinRoom(tstId1, "lobby")
    roomLogic.joinRoom(tstId2, "lobby")
    assert true == roomLogic.rooms["lobby"].clients.contains(tstId1)
    assert true == roomLogic.rooms["lobby"].clients.contains(tstId2)

    let peers = roomLogic.getParticipatingClients(tstId1)
    assert true == peers.contains(tstId2)

    roomLogic.leaveRoom(tstId2, "lobby")
    assert roomLogic.getParticipatingClients(tstId1).len == 0
