{EventEmitter}  = require "events"
es              = require "event-stream"

module.exports = ->
  db:
    name: "test-model"
    find: (id, cb) -> cb null, null
    upsert: (id, doc, cb) -> cb null
  model: new EventEmitter
  sourceStream: es.through (data) -> @queue data
  sourceToIdPieces: (doc) -> [doc.type, doc.field]
  subscriberStreams: []
  schema: ["type", "field"]
  version: "test-version"
