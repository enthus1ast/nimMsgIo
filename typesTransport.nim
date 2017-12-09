import typesMsgIo, asyncdispatch

type
  TransportSend* = proc (transport: TransportBase, clientId: ClientId, event, data: string): Future[void] {.closure, gcsafe.}
  TransportBase* = object of RootObj
    proto*: string
    send*: TransportSend
    # hasClient*: -> bool