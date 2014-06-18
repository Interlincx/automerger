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
      assert.equal doc.keyPart1, 'none'
      assert.equal doc.keyPart2, 'name'
      assert.equal doc.version, 'test-version'

      done()

    conf = getBasicConfig()
    conf.subscriberStreams.push es.through onJob

    am = new AutoMerger conf

    sourceDoc =
      current: {keyPart1: 'none', keyPart2: 'name'}

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
      current: {keyPart1: 'none', keyPart2: 'name'}

    am.sourceStream.write sourceDoc

  it 'should save new', (done) ->

    onUpsert = (id, doc, cb) ->
      assert.equal id, 'none!name'
      assert.equal doc._id, 'none!name'
      assert.ok doc.createdAt
      assert.equal doc.keyPart1, 'none'
      assert.equal doc.keyPart2, 'name'
      assert.equal doc.version, 'test-version'

      cb null

    onJob = (job) ->
      assert.equal job.action, 'create'
      assert.equal job.name, 'test-model'
      done()

    conf = getBasicConfig()
    conf.db.upsert = onUpsert
    conf.subscriberStreams.push es.through onJob

    am = new AutoMerger conf

    sourceDoc =
      current: {keyPart1: 'none', keyPart2: 'name'}

    am.sourceStream.write sourceDoc

  it 'should update existing', (done) ->

    originalTarget = _id: 'none!name', keyPart1: 'none', keyPart2: 'name', createdAt: (new Date).toString()

    onUpsert = (id, doc, cb) ->
      assert.equal id, 'none!name'
      assert.equal doc._id, 'none!name'
      assert.equal doc.nonKeyField, true # new field was set
      assert.ok doc.createdAt
      assert.ok doc.updatedAt
      assert.equal doc.keyPart1, 'none'
      assert.equal doc.keyPart2, 'name'
      assert.equal doc.version, 'test-version'

      cb null

    onJob = (job) ->
      assert.equal job.action, 'update'
      assert.equal job.name, 'test-model'

      assert.notOk job.previous.nonKeyField, 'nonKeyField field was NOT defined on original'
      assert.notOk job.previous.updatedAt
      assert.ok job.current.nonKeyField, 'nonKeyField field IS defined on current'
      assert.ok job.current.updatedAt
      done()

    conf = getBasicConfig()
    conf.db.upsert = onUpsert
    conf.db.find = (id, cb) -> cb null, originalTarget
    conf.subscriberStreams.push es.through onJob

    am = new AutoMerger conf

    sourceDoc =
      current:
        keyPart1: 'none'
        keyPart2: 'name'
        nonKeyField: true

    am.sourceStream.write sourceDoc
