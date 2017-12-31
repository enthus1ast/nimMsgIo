#
#
#                      msgIo
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
# from types import ClientId
import sets, tables
import typesShared
export typesShared
 
type # Both
  NameSpaceIdent* = string # "mandant" rooms with same name could exists on multiple NameSpaces
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
    # nameSpaceIdent*: NameSpaceIdent # the namespace this server is responsible for
    clients*: Clients # all connected clients
    nameSpaces*: NameSpaces # all created namespaces
  NameSpace* = object
    nameSpaceIdent*: NameSpaceIdent
    rooms*: Rooms # all created rooms.
  NameSpaces* = TableRef[NameSpaceIdent, NameSpace]

