import std / [ os, tables, hashes, streams, sequtils ]

import frosty
import supersnappy
import ws
import packedjson
import uuids
import gram

# needed for ws because dumb
import std / [ asyncdispatch, asynchttpserver ]

const
  graphOptions = {UniqueEdges, Directed, ValueIndex}

type
  GunId = UUID            # until proven otherwise...
  WireGraph = JsonNode    # graph on the wire
  Lexical = object

  Message = object
    at: GunId          # message references this id
    node: GunNode      # message body node
    get: Lexical
    put: WireGraph
    err: string        # errors
    ok: string         # "non-standard"

  GunGraph = Graph[GunNode, GunEdge, graphOptions.toInt]
  GunNode = object  ## nodes have an id and json tree
    id: GunId
    data: JsonTree
  GunEdge = string  ## edges are json object keys

template id(message: Message): GunId = message.node.id
template parseGunId(js: JsonNode): GunId = parseUUID(getStr js)

proc parseGunNode(js: sink JsonTree): GunNode =
  if "_" in js:
    result.id = parseGunId js["_"]["#"]
    delete js, "_"
    result.data = js
  else:
    raise newException(ValueError, "missing metadata")

proc parseGunNode(js: JsonNode): GunNode =
  result = parseGunNode(copy js)

proc dewireMessage(js: JsonNode): Message =
  if "@" in js:
    result.at = parseGunId js["@"]
  if "err" in js:
    result.err = getStr js["err"]
  if "ok" in js:
    result.ok = getStr js["ok"]

proc parseMessage(s: Stream): Message =
  assert s.peekChar == '{'
  var js: JsonTree = parseJson(s)
  result = dewireMessage(JsonNode js)

proc parseMessages(s: Stream): seq[Message] =
  assert s.peekChar == '['
  var js: JsonTree = parseJson(s)
  assert js.kind == JArray
  result.setLen js.len
  for j in items js:
    result.add dewireMessage(j)

proc makeGunGraph*(): GunGraph = newGraph[GunNode, GunEdge] graphOptions

when false:
  # treeform's echo server for ws reference
  var server = newAsyncHttpServer()
  proc callback(req: Request) {.async.} =
    if req.url.path == "/ws":
      var ws = await newWebSocket(req)
      await ws.send("Welcome to simple echo server")
      var count = 0
      while ws.readyState == Open:
        #let packet = await ws.receiveStrPacket()
        await sleepAsync 1000
        await ws.send($count)
        inc count
    else:
      await req.respond(Http404, "Not found")

  waitFor server.serve(Port 9001, callback)
