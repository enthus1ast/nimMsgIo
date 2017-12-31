#
#
#                      msgIo
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

# type

  # NameSpace = object
  #   name: string
  #   roomLogic: RoomLogic
  # NameSpaces = TableRef[string, NameSpace]

const DEFAULT_NAMESPACE*: NameSpaceIdent = "default"

proc newClients*(): Clients =
  result = initSet[ClientId]()

proc newRooms*(): Rooms =
  result = newTable[RoomId, Room]()
  
proc newNamespace(nameSpaceIdent: NameSpaceIdent): NameSpace = 
  result = NameSpace()
  result.nameSpaceIdent = nameSpaceIdent
  result.rooms = newRooms()
  # result.roomLogic = newRoomLogic()

proc newNamespaces(): NameSpaces = 
  result = newTable[string, NameSpace]()

proc registerNamespace(roomLogic: RoomLogic, nameSpace: NameSpaceIdent) =
  roomLogic.nameSpaces.add(nameSpace, newNamespace(nameSpace))


proc newRoomLogic*(namespaces: seq[NameSpaceIdent] = @[DEFAULT_NAMESPACE]): RoomLogic =
  randomize()
  result = RoomLogic()
  # result.nameSpaceIdent = nameSpaceIdent
  result.clients = newClients()
  result.namespaces = newNamespaces()
  for nsp in namespaces:
    result.registerNamespace nsp

proc newRoom*(roomId: RoomId): Room = 
  result = Room()
  result.roomId = roomId
  result.clients = newClients()

template testNamespace() {.dirty.} = 
  if not roomLogic.nameSpaces.contains nameSpace:
    echo "nameSpace unknown!:", namespace
    return   

template testClient() {.dirty.} = 
  if not roomLogic.clients.contains clientId:
    echo "connect client first!:", clientId
    return

template varNsp() {.dirty.} = 
  var nsp = roomLogic.nameSpaces[namespace]     

proc getNsp*(roomLogic: RoomLogic, namespace: NameSpaceIdent = DEFAULT_NAMESPACE): NameSpace = 
  varNsp
  return nsp

proc joinRoom*(roomLogic: RoomLogic, clientId: ClientId, roomId: RoomId, namespace = DEFAULT_NAMESPACE) =
  ## let client join the given room
  ## if room does not exist create it.
  testNamespace 
  testClient
  var nsp = roomLogic.nameSpaces[namespace]
  if not nsp.rooms.hasKey(roomId):
    nsp.rooms[roomId] = newRoom(roomId)
  nsp.rooms[roomId].clients.incl(clientId)

proc leaveRoom*(roomLogic: RoomLogic, clientId: ClientId, roomId: RoomId, namespace = DEFAULT_NAMESPACE) = 
  ## let client part from the given room
  ## if room is empty afterwards remove it
  testNamespace 
  testClient  
  varnsp  
  if not nsp.rooms.hasKey(roomId):
    return
  nsp.rooms[roomId].clients.excl(clientId)
  if nsp.rooms[roomId].clients.len == 0:
    # if room empty remove close room
    nsp.rooms.del(roomId)

proc leaveAllRooms*(roomLogic: RoomLogic, clientId: ClientId, namespace = DEFAULT_NAMESPACE) = 
  ## clients leaves all rooms it is connected to.
  testNamespace 
  testClient  
  varnsp   
  for room in nsp.rooms.values:
    if room.clients.contains(clientId):
      roomLogic.leaveRoom(clientId, room.roomId) # room.del(client.clientId)
  
proc getParticipatingClients*(roomLogic: RoomLogic, clientId: ClientId, namespace = DEFAULT_NAMESPACE): HashSet[ClientId] =
  ## returns a set with all clientId's the given clientId is in contact with
  testNamespace 
  testClient  
  varnsp    
  result = initSet[ClientId]()
  for room in nsp.rooms.values:
    # echo room
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

proc connects*(roomLogic: RoomLogic, clientId: ClientId, namespace = DEFAULT_NAMESPACE): bool = 
  ## connects a client to the underlying logic
  if roomLogic.clientIdUsed(clientId): return false
  roomLogic.clients.incl(clientId)
  return true

proc disconnects*(roomLogic: RoomLogic, clientId: ClientId, namespace = DEFAULT_NAMESPACE) =
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
    assert roomLogic.namespaces["default"].rooms.len() == 1
    assert roomLogic.namespaces["default"].rooms["lobby"].clients.len() == 1
    
    roomLogic.leaveRoom(tstId, "lobby")
    roomLogic.leaveRoom(tstId, "lobby") # leave again
    assert roomLogic.namespaces["default"].rooms.len() == 0

    roomLogic.joinRoom(tstId, "tst")
    roomLogic.joinRoom(tstId, "tst2")
    assert roomLogic.namespaces["default"].rooms.len() == 2
    roomLogic.leaveAllRooms(tstId)
    assert roomLogic.namespaces["default"].rooms.len() == 0

  block:
    var roomLogic = newRoomLogic()
    assert true == roomLogic.connects tstId1
    roomLogic.joinRoom(tstId1, "lobby")
    assert roomLogic.namespaces["default"].rooms.hasKey("lobby")
    roomLogic.disconnects(tstId1)
    assert false == roomLogic.namespaces["default"].rooms.hasKey("lobby")

  block:
    var roomLogic = newRoomLogic()
    assert true == roomLogic.connects tstId1
    assert true == roomLogic.connects tstId2
    assert true == roomLogic.clients.contains(tstId1)
    assert true == roomLogic.clients.contains(tstId2)
    
    roomLogic.joinRoom(tstId1, "lobby")
    roomLogic.joinRoom(tstId2, "lobby")
    assert true == roomLogic.namespaces["default"].rooms["lobby"].clients.contains(tstId1)
    assert true == roomLogic.namespaces["default"].rooms["lobby"].clients.contains(tstId2)

    let peers = roomLogic.getParticipatingClients(tstId1)
    assert true == peers.contains(tstId2)

    roomLogic.leaveRoom(tstId2, "lobby")
    assert roomLogic.getParticipatingClients(tstId1).len == 0
