type
  MsgType* = enum
    CLIENT_TO_GROUP
    CLIENT_TO_SERVER
    SERVER_TO_CLIENT
    SERVER_TO_GROUP
    CLIENT_TO_CLIENT
  # MsgTypeSend* = enum
  #   TO_GROUP
  #   TO_SERVER
  #   TO_CLIENT
  # MsgServerSends =

  # MsgClientSends = 
  
  MsgBase* = object of RootObj
    target*: string
    # msgType*: MsgType
    event*: string
    payload*: string
    # msgId*: int
  
  # MsgRecv* = object of MsgBase
  #   tType*: MsgType
  # MsgSend* = object of MsgBase
  #   targetType*: MsgTypeSend
  # # MsgToServer* = object


