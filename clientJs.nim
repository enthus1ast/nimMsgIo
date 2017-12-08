# when not defined(js):
#   echo "this module is for the js backend!"
#   quit()
# import tables
type

  MessageEvent* {.importc.} = ref object
    data*: cstring

  WebSocket* {.importc.} = ref object
    onmessage*: proc (e: MessageEvent)
    onopen*: proc (e: MessageEvent)

  WebsocketIoClient = object
    ws: WebSocket


proc newWebSocket(url, key: cstring): WebSocket
  {.importcpp: "new WebSocket(@)".}

proc send(w: WebSocket; data: cstring) {.importcpp.}

proc newWebsocketIoClient*(url, namespace: string): WebsocketIoClient = 
  ## The websocketIo Client.
  result = WebsocketIoClient()
  result.ws = newWebSocket(url, namespace)
  # result.ws.onopen = 

proc joinRoom*(wic: WebsocketIoClient, room: string) =
  ## tells the server we want to join a room
  ## if sucessfull onJoinedRoom(room, success) is called
  discard

proc leaveRoom*(wic: WebsocketIoClient, room: string) = 
  ## tells the server we want to leave a room
  ## if sucessfull onLeaveRoom(room, success) is called
  discard

proc sendToRoom*(wic: WebsocketIoClient, room: string, event: string, data: string) =
  ## sends data to the given room. The client must have joined the room before.
  ## if the server accepts, then the message is relayed to all clients in the room
  discard

proc sendToUser*(wic: WebsocketIoClient, userId: string, event: string, data: string ) =
  ## sends data to the given user. 
  ## If server accepts, data is relayed to the given user
  discard

proc send*(wic: WebsocketIoClient, event: string, data: string ) =
  ## sends data withouth a target. Server has to distribute or handle this call 
  ## in its onMsg callback. 

proc on*(wic: WebsocketIoClient, event: string, cb: proc () ) = 
  discard
  # wic.callbacks.add()

when isMainModule:
  var wic = newWebsocketIoClient("ws://127.0.0.1:8081", "default")
  wic.ws.onopen = proc (e: MessageEvent) = 
    # ws.send("foo")
    wic.joinRoom("lobby")
