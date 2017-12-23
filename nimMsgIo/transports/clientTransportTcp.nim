import asyncnet, asyncdispatch
import ../typesSerializer
import ../typesClient

type
  ClientTransportTcp* = ref object of ClientTransportBase
    client*: AsyncSocket

proc connectTcp(client: ClientTransportTcp, host: string, port: int): Future[bool] {.async.} =
  discard

proc newClientTransportTcp*(client: MsgIoClient, serializer: SerializerBase): ClientTransportTcp =
  result = new ClientTransportTcp
  result.client = newAsyncSocket()
  result.msgIoClient = client
  result.serializer = serializer
  var transport = result
  client.transportConnect = proc (client: MsgIoClient, host: string, port: int): Future[bool] {.closure, gcsafe.} =
    transport.connectTcp(host, port)