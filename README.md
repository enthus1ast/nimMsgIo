nimMsgIo

1. a modular, multi protocol, room based, message distribution server.
2. variouse clients (native, browser) for speaking agains the msgIo server.

Let clients join rooms and let them share messages between those rooms.


the structure of this library is as follow:

transports/
  ## implementing the actual protocols
  ## this library is able to speek
  transportWebSocket # transport for the websocket protocol, also implements http callbacks
  transportTcp       # transport for plain TCP (net syntax)
  transportUdp       # transport for plain UDP

serializer/
  ## implements the variouse serializers every transport can use to
  ## convert a msgIo object into the aproprirate(?) byte streams.
  ## Which can than be transfered over the transports communication channel
  serializerJson
  serializerMsgPack 
