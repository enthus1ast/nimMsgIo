import net, strutils
import ../transports/typesTransportTcp

echo sizeof(uint32)
var socket = newSocket()
socket.connect("127.0.0.1", 9001.Port)
socket.send("msgio")

let line = "asd".repeat(2).toTransportTcpLine()
echo line
echo ($line).len
socket.send($line)