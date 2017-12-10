import typesShared, typesMsg, asyncdispatch

type 

    ws: WebSocket 
  MsgIoClient = object
    clientId: ClientId

# proc newMsgIoClient[T](): MsgIoClient =
#   result = MsgIoClient()
#   send


when isMainModule:

  # wie will ichs benutzen nummer 1

  # client.onClientConnected = proc() =
  #   client.send("group", "updateLobby" , "data")
  # client.connect("127.0.0.1", 9090)
  # proc connect(msgio: MsgIoClient, address: string, port: int) {.async.} =
    
    

  proc main() {.async.} =
    var client = newMsgIoClient[ClientWebsocket]()
    if not (await client.connect("127.0.0.1", 9090)):
      echo "could not connect to server"
      return
    await client.send("group", "updateLobby" , "data")
  waitFor main()