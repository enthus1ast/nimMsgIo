import websocket, sets, tables, asyncnet
import asyncdispatch, asynchttpserver

type
  ClientId = int

  Server = object
    # clients: table[ClientId, Client]
    clients: HashSet[ClientId]
    userConnected: proc (server: Server, clientId: ClientId)


type
  WS* = object
    txt*: string
    httpServer: AsyncHttpServer
    clients: TableRef[ClientId, AsyncSocket]
    userConnected: proc (server: Server, clientId: ClientId)



proc send(trans: WS, data: string){.async.}=
  echo "would send from ws:", data
  return

# proc userConnected*(trans: WS): Future[ClientId] {.async.}=

#   trans.httpServer.serve(9090, proc (req: Request): Future[void] =
#     return
#   )
#   discard
#   await sleepAsync(1000)
#   return 0

proc newWs(userConnected: proc (server: Server, clientId: ClientId) ): WS =
  result = WS()
  result.httpServer = AsyncHttpServer()
  result.userConnected = userConnected# (server: Server, clientId: ClientId)
# proc send*() {.async.} = discard

proc userConnected() {.async.} = discard

proc close() {.async.} = discard