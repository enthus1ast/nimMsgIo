import typesMsgIo
# import transport
import typesTransport
import asyncdispatch
import sequtils

type
  Transports = seq[TransportBase]
  MsgIoServer* = ref object
    discard
    transports: Transports

proc newMsgIoServer*(): MsgIoServer = 
  result = MsgIoServer()
  result.transports = @[]

proc addTransport(msgio: MsgIoServer, transport: TransportBase) = 
# proc addTransport(msgio: MsgIoServer, transport: T) = 
  # var base = TransportBase()
  # base.send = transport.send
  # echo repr transport.send
  msgio.transports.add transport
  # msgio.transport.send()



when isMainModule:
  import transport
  var transportWs = newTransportWs()
  var msgio = newMsgIoServer()
  addTransport(msgio, transportWs)
  assert msgio.transports.len == 1
  echo msgio.transports
  var ts = msgio.transports[0].send
  echo repr ts
  # ts[TransportSend]()
  waitFor ts(1234, "event", "data")
  # discard await  
  # assert msg
  # waitFor msgio.transports[0].send()
  # msgio.addTransport(transportWs)
  # msgio.addTransport(tcptransport)
  