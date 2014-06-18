assert = require('chai').assert
{EventEmitter} = require 'events'
es = require "event-stream"

AutoMerger = require '../src/index'
getBasicConfig = require './fixtures/basic-config'

describe 'AutoMerger', ->
  it 'should instantiate', ->
    minViableConfig =
      db:
        name: ''
      model: new EventEmitter
      sourceStream:
        pipe: ->
        resume: ->

    am = new AutoMerger minViableConfig
    assert.ok am

  it 'should push to subscribers', (done) ->

    onJob = (job) ->

      assert.equal job.action, 'create'
      assert.equal job.name, 'test-model'

      doc = job.current
      assert.equal doc._id, 'none!name'
      assert.ok doc.createdAt
      assert.equal doc.type, 'none'
      assert.equal doc.field, 'name'
      assert.equal doc.version, 'test-version'

      done()

    conf = getBasicConfig()
    conf.subscriberStreams.push es.through onJob

    am = new AutoMerger conf

    sourceDoc =
      current: {type: 'none', field: 'name'}

    am.sourceStream.write sourceDoc

  it 'should migrate', (done) ->
    conf = getBasicConfig()
    existingDoc = {field1: 'ok', another: true}

    # an existing document is returned by `find`
    conf.db.find = (id, cb) -> cb null, existingDoc

    conf.subscriberStreams.push es.through (job) ->
      # subscriptionStream receives the migrated document
      assert.equal job.current.field2, 'sure'
      assert.equal job.current.field3, true

      done()

    conf.migrator = (doc) ->
      # check initial state
      assert.deepEqual doc, existingDoc

      # do migration
      delete doc.field1
      delete doc.another
      doc.field2 = 'sure'
      doc.field3 = true

      return doc

    am = new AutoMerger conf

    sourceDoc =
      current: {type: 'none', field: 'name'}

    am.sourceStream.write sourceDoc
