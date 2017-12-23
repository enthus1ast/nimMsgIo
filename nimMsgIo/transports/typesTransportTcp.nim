#
#
#                      msgIo
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
import streams, asyncdispatch, options, asyncnet

type
  TransportTcpLine* = object
    size*: uint32
    data*: string

proc toTransportTcpLine*(str: string): TransportTcpLine =
  if str.len > high(uint32).int: raise newException(ValueError, "payload is too long for this tcp transport")
  result = TransportTcpLine()
  result.size = str.len.uint32
  result.data = str

proc `$`*(line: TransportTcpLine): string =
  var ss = newStringStream()
  ss.write(line.size)
  ss.write(line.data)
  return ss.data

proc recvTransportTcpLine*(socket: AsyncSocket, maxMsgLen = 64_000): Future[Option[string]] {.async.} =
    var buffer: string 
    var msgLen: int
    # var line = TransportTcpLine()
    # read the msg len
    try:
      buffer = await socket.recv( sizeof(uint32) )
    except:
      echo getCurrentExceptionMsg()
      return
    if buffer.len == 0: return
    var msgLenStr = newStringStream( buffer )

    try:
      msgLen = msgLenStr.readUint32().int
    except:
      echo getCurrentExceptionMsg()
      echo "could not read int from msgLenStr"
      return

    if msgLen > maxMsgLen: 
      echo "msg to large!: ", msgLen
      return

    # read the payload message
    try:
      buffer = await socket.recv( msgLen )
    except:
      echo getCurrentExceptionMsg()
      return
    if buffer.len == 0: return
    # let msgStr = buffer
    
    return some buffer