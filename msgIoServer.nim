import types
import asyncdispatch
import sequtils

proc newMsgIoServer*(): MsgIoServer = 
  result = MsgIoServer()
  result.transports = @[]

proc addTransport(msgio: MsgIoServer, transport: TransportBase) = 
  msgio.transports.add transport



when isMainModule:
  import transports/transportWebSocket
  var 
    transportWs = newTransportWs()
    msgio = newMsgIoServer()
  msgio.addTransport(transportWs)
  assert msgio.transports.len == 1
  echo msgio.transports
  discard msgio.transports[0].send(msgio, 123.ClientId, "event", "data")