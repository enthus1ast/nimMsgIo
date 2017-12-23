import typesMsg
export typesMsg
import options

type
  SerializerSerialize = proc (msg: MsgBase): Option[string]
  SerializerUnSerialize = proc (msgstr: string): Option[MsgBase]
  SerializerBase* = object of RootObj
    serialize*: SerializerSerialize
    unserialize*: SerializerUnSerialize