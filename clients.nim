# # this the preamble code to write clients

import asyncdispatch, options
export asyncdispatch, options

import nimMsgIo/types
export types

import nimMsgIo/msgIoClient2
export msgIoClient2

import nimMsgIo/transports/clientTransportTcp
export clientTransportTcp

import nimMsgIo/transports/clientTransportWebSocket
export clientTransportWebSocket

import nimMsgIo/serializer/serializerJson
export serializerJson

import nimMsgIo/serializer/serializerMsgPack
export serializerMsgPack

