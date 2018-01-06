import ../types, asyncdispatch

type RpcContext* = object
  # foo: seq[string] # = @["foo", "baa"]
  msgio: MsgIoServer

proc newRpcContext*(msgio: MsgIoServer): RpcContext = 
  result = RpcContext()
  result.msgio = msgio

proc onClientMsgRPC*(rpc: RpcContext, msg: MsgBase, clientId: ClientId, transport: TransportBase): Future[void] {.async, gcsafe.} = 
  discard
  # foo.add("baa")