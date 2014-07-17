{EventEmitter}  = require "events"
es              = require "event-stream"

module.exports = ->
  db:
    name: "test-model"
    find: (id, cb) -> cb null, null
    upsert: (id, doc, cb) -> cb null
  sourceStream: es.duplex [
    es.through (data) -> @queue data
    es.through()
  ]...
  sourceToIdPieces: (doc) -> [doc.keyPart1, doc.keyPart2]
  subscriberStreams: []
  schema: ["keyPart1", "keyPart2", "nonKeyField"]
  version: "test-version"
