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

  it 'model should emit "reject" with rejectSource fn', (done) ->
    conf = getBasicConfig()
    conf.rejectSource = (doc) -> return true # always reject
    conf.db.upsert = -> assert.fail 'should not save a rejected document'
    conf.subscriberStreams.push es.through ->
      assert.fail 'should not notify subscribers of rejected docs'

    conf.model.on 'reject', (doc) ->
      console.log "doc: ", doc
      assert.ok doc, 'rejected document as expected'
      done()

    am = new AutoMerger conf

    sourceDoc =
      current:
        keyPart1: 'none'
        keyPart2: 'name'
        nonKeyField: true

    am.sourceStream.write sourceDoc

  it 'model should emit "reject" with incomplete id', (done) ->
    conf = getBasicConfig()
    conf.db.upsert = -> assert.fail 'should not save a rejected document'
    conf.subscriberStreams.push es.through ->
      assert.fail 'should not notify subscribers of rejected docs'

    conf.model.on 'reject', (doc) ->
      assert.ok doc, 'rejected document as expected'
      done()

    am = new AutoMerger conf

    sourceDoc =
      current:
        keyPart1: 'none'
        # keyPart2: 'name' # source is missing keyPart2, an idPiece
        nonKeyField: true

    am.sourceStream.write sourceDoc

  it 'model should emit "reject" with unchanged target', (done) ->
    originalTarget = _id: 'none!name', keyPart1: 'none', keyPart2: 'name', createdAt: (new Date).toString()

    conf = getBasicConfig()

    conf.db.find = (id, cb) -> cb null, originalTarget
    conf.db.upsert = -> assert.fail 'should not save a rejected document'

    conf.subscriberStreams.push es.through ->
      assert.fail 'should not notify subscribers of rejected docs'

    conf.model.on 'reject', (doc) ->
      assert.ok doc, 'rejected document as expected'
      done()

    am = new AutoMerger conf

    sourceDoc =
      current:
        keyPart1: 'none'
        keyPart2: 'name'

    am.sourceStream.write sourceDoc

  it 'should be not_ready', (done) ->
    conf = getBasicConfig()
    conf.readyProperties = ['readyField']

    conf.db.upsert = (id, doc, cb) ->
      assert.ok id
      assert.ok doc
      cb null

    conf.subscriberStreams.push es.through ->
      assert.fail 'should not notify subscribers of unready docs'

    conf.model.on 'not_ready', (doc) ->
      assert.ok doc, 'document not ready as expected'
      done()

    am = new AutoMerger conf

    sourceDoc =
      current:
        keyPart1: 'none'
        keyPart2: 'name'
        nonKeyField: true
        # readyField: true #readyProperty not present

    am.sourceStream.write sourceDoc
