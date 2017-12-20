import net, strutils, os, options
import ../transports/typesTransportTcp
import ../serializer/serializerJson
import ../typesMsg

echo sizeof(uint32)
var socket = newSocket()
socket.connect("127.0.0.1", 9001.Port)
socket.send("msgio")

var ser = newSerializerJson()
var msg = MsgBase()
msg.event = "testevent"
msg.payload = "tespayload"
msg.target = "from tcp client test"
var serOpt = ser.serialize( msg )

var line = serOpt.get().toTransportTcpLine()
while true:
  socket.send($line)
  # sleep(150)
# socket.send($ "asd".repeat(3).toTransportTcpLine())
# socket.send($ "asd".repeat(4).toTransportTcpLine())
