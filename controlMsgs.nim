#
#
#                   WebsocketIO
#        (c) Copyright 2017 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
type
  MsgToServer = object
    target: string
    toGroup: bool
    payload: string
  MsgFromServer = object
    sender: string
    target: string
    fromGroup: bool
    payload: string
