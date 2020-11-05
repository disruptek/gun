import testes
import uuids
import packedjson

include gun # for "private" symbol testing

let
  a = $genUUID()
  b = $genUUID()
  exampleGraph = %* {
    a: {"_": {"#": a},
      "name": "Mark Nadal",
      "boss": {"#": b}
    },
    b: {"_": {"#": b},
      "name": "Fluffy",
      "species": "kitty",
      "slave": {"#": a}
    }
  }

testes:
  block:
    ## make a graph
    var graph = makeGunGraph()

  block:
    ## parse a node
    var js = parseJson($exampleGraph)
    let anode = parseGunNode(js[a])
    let bnode = parseGunNode(js[b])
    assert $anode.id == a
    assert $bnode.id == b
