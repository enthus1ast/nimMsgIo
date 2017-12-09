import typesMsgIo, asyncdispatch

type
  TransportSend* = proc (clientId: ClientId, event, data: string): Future[void] {.closure, gcsafe.}
  TransportBase* = object of RootObj
    proto*: string
    send*: TransportSend
    # hasClient*: -> bool