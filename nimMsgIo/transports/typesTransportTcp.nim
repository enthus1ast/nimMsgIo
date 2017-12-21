#
#
#                      msgIo
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
import streams

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