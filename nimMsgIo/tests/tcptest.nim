import net, strutils, os, options, random
import ../transports/typesTransportTcp
import ../serializer/serializerJson
import ../typesMsg

echo sizeof(uint32)
var socket = newSocket()
socket.connect("127.0.0.1", 9001.Port)
socket.send("msgio")

var ser = newSerializerJson()
var msg = newMsgBase()

while true:
  msg.event = "testevent"
  msg.payload = "tespayload".repeat(rand(100))
  msg.target = "from tcp client test"
  var serOpt = ser.serialize( msg )
  var line = serOpt.get().toTransportTcpLine()
  socket.send($line)
  sleep(550)
# socket.send($ "asd".repeat(3).toTransportTcpLine())
# socket.send($ "asd".repeat(4).toTransportTcpLine())
