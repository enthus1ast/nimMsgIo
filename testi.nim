import sets, asyncdispatch

type
  ClientId = int


  Server = object
    # clients: table[ClientId, Client]
    clients: HashSet[ClientId]

  TCP = object
    txt: string


# proc send[T](data: string) = 
#   T.send(data)

proc handleUser(user: ClientId) =
  discard



proc send(trans: TCP, data: string) =
  echo "would send from TCP:", data


proc userConnected(server: Server, clientId: ClientId) =
  echo "transport called servers userConnected with ", clientId

  #... 
  userCallbackConnecting()
  userCallbackConnected()


# proc handle[T](trans: T) {.async.} =
#   while true:
#     var user = await trans.userConnected()
#     handleUser(user)

when isMainModule:
  import testiWs
  var ws = newWs(userConnected = userConnected)

  asyncCheck ws.handle()
  # var tcp = TCP()
  # ws.send("foo")
  # tcp.send("foo")
  runForever()