# nimMsgIo
## Whats the plan:
1. a modular, multi protocol, room based, message distribution server.
2. variouse clients (native, browser) for speaking agains the msgIo server.

Let clients join rooms and let them share messages between those rooms.

the structure of this library is as follow:

```

transports/
  ## implementing the actual protocols
  ## this library is able to speek
  transportWebSocket # transport for websocket and http
  transportTcp       # transport for plain TCP (net syntax)
  transportUdp       # transport for plain UDP ( !not yet done! )

serializer/
  ## implements the variouse serializers every transport can use to
  ## convert a msgIo object into the appropriate byte streams.
  ## Which can than be transfered over the transports communication channel
  serializerJson
  serializerMsgPack 

types*
  ## typedefinitions for clients and server

examples/
  ## server and client examples
```

# Join rooms
Clients can be grouped in "rooms". Every client can participate in multiple rooms. 
Clients can ask the server to join them in rooms. But the server has to fullfill this request via its `joinRoom` proc.

To let clients join rooms the programmer must call joinRoom `on the server`.
The server can then send messages to the room via `toRoom` 

# Send to clients
Clients can NOT send "directly" to other clients.
The server have to provide code to distribute a request

an example would be
```nim
await msgio.send(clientId, "event", "data")
await msgio.broadcast("event", "my message")
await msgio.toRoom("lobby", "some_event", msg.payload, namespace = "chat")
```
- send sends directly to a user id
- a broadcast is distributed to all connected clients. This does not respect the namespace!
- toRoom sends a message to all room members. Accepts a namespace!

# Examples
have a look at ./nimMsgIo/msgIoServer.nim