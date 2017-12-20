# when not defined(js):
#   echo "this module is for the js backend!"
#   quit()
# import tables
# import controlMsgs
import typesMsg
import json
# import types

type

  MessageEvent* {.importc.} = ref object
    data*: cstring

  WebSocket* {.importc.} = ref object
    onmessage*: proc (e: MessageEvent)
    onopen*: proc (e: MessageEvent)

  MsgIoClient = object
    ws: WebSocket

proc newWebSocket(url, key: cstring): WebSocket
  {.importcpp: "new WebSocket(@)".}

proc send(w: WebSocket; data: cstring) {.importcpp.}

proc newMsgIoClient*(url, namespace: cstring): MsgIoClient {.exportc.} = 
  ## The websocketIo Client.
  result = MsgIoClient()
  result.ws = newWebSocket($url, $namespace)
  # result.ws.onopen = 

proc joinRoom*(wic: MsgIoClient, room: string) =
  ## tells the server we want to join a room
  ## if sucessfull onJoinedRoom(room, success) is called
  discard

# proc leaveRoom*(wic: MsgIoClient, room: string) = 
#   ## tells the server we want to leave a room
#   ## if sucessfull onLeaveRoom(room, success) is called
#   discard

# proc sendToRoom*(wic: MsgIoClient, room: string, event: string, data: string) =
#   ## sends data to the given room. The client must have joined the room before.
#   ## if the server accepts, then the message is relayed to all clients in the room
#   discard

# proc sendToUser*(wic: MsgIoClient, userId: string, event: string, data: string ) =
#   ## sends data to the given user. 
#   ## If server accepts, data is relayed to the given user
#   discard

proc send*(wic: MsgIoClient, event: cstring, data: cstring ) {.exportc.}=
  ## sends data withouth a target. Server has to distribute or handle this call 
  ## in its onMsg callback. 
  # var j = .stringify( {event: "foo", payload: "pay", target: "tar"} )
  var msg = MsgBase()
  msg.event = $event
  msg.payload = $data
  msg.target = "NOT YET in CLIENT"
  let j = $ %*msg
  # echo j
  wic.ws.send(j.cstring)


proc on*(wic: MsgIoClient, event: string, cb: proc () ) = 
  discard
  # wic.callbacks.add()

when isMainModule:
  var wic = newMsgIoClient("ws://127.0.0.1:9000", "default")
  wic.ws.onopen = proc (e: MessageEvent) = 
    # ws.send("foo")
    wic.joinRoom("lobby")
    wic.send("event", "datapayload")
