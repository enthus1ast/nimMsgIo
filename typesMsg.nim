type
  MsgType* = enum
    TGROUP
    TCLIENT
    TSERVER
  MsgBase* = object of RootObj
    target*: string
    sourceType: MsgType
    targetType: MsgType
    event*: string
    payload*: string
    # msgId*: int