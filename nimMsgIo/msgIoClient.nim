#
#
#                      msgIo
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
import typesShared, typesMsg, asyncdispatch, websocket, asyncnet

type 

    # ws: WebSocket 
  MsgIoClient[T] = object
    clientId: ClientId
    transport: T

  TransportWs = object
    socket: AsyncWebSocket

  TransportTcp = object
    socket: AsyncSocket

  NetMsg = object

proc send(trans: TransportWs, msgSerialized: string): Future[void] {.async.} =
  echo "send from TransportWs"
  # await trans.socket.send(msgSerialized)

proc connect(trans: TransportWs, address: string, port: int): Future[void] {.async.} =
  echo "send from TransportWs"
  # await trans.socket.send(msgSerialized)

proc init(trans: var TransportWs) =
  trans.socket = newAsyncWebSocket()

proc init(trans: var TransportTcp) =
  trans.socket = newAsyncSocket()

# proc init(trans: var TransportFoo) =
#   trans.clients = initTable[ClientId, FOOBAA]


proc send(trans: TransportTcp, msgSerialized: string): Future[void] {.async.} =
  echo "send from TransportTCP"
  # await trans.socket.send(msgSerialized)

proc newMsgIoClient[T](): MsgIoClient[T] =
  result = MsgIoClient[T]()
  result.transport.init()
  # send

proc newNetMsg(group, event, data: string): NetMsg  = 
  return NetMsg()

proc serialize(msg: NetMsg): string =
  return "nix"

proc send(client: MsgIoClient, group, event, data: string): Future[void] {.async.} =
  let netMsg = newNetMsg(group, event, data)
  let ser = netMsg.serialize()
  await client.transport.send(ser)

# client.on "cheater":
#   foo baa

when isMainModule:

  # wie will ichs benutzen nummer 1

  # client.onClientConnected = proc() =
  #   client.send("group", "updateLobby" , "data")
  # client.connect("127.0.0.1", 9090)
  # proc connect(msgio: MsgIoClient, address: string, port: int) {.async.} =
    
  var clientWs = newMsgIoClient[TransportWs]()
  # var ws = TransportWs[TransportWs]()
  waitFor clientws.send("group", "event", "data")

  # var clientTcp = newMsgIoClient[TransportTcp]()
  # # var ws = TransportWs[TransportWs]()
  # waitFor clientTcp.send("group", "event", "data")


  # proc main() {.async.} =
  #   var client = newMsgIoClient()
  #   if not (await client.connect("127.0.0.1", 9090)):
  #     echo "could not connect to server"
  #     return
  #   await client.send("group", "updateLobby" , "data")
  # waitFor main()