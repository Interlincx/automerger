assert = require('chai').assert
{EventEmitter} = require 'events'
es = require "event-stream"

AutoMerger = require '../src/index'
getBasicConfig = require './fixtures/basic-config'
getMinConfig = require './fixtures/min-config'

describe 'AutoMerger', ->
  it 'should instantiate', ->
    am = new AutoMerger getMinConfig()
    assert.ok am
    assert.ok am instanceof AutoMerger

  it 'should instantiate without "new"', ->
    am = AutoMerger getMinConfig()
    assert.ok am
    assert.ok am instanceof AutoMerger

  it 'should push to a subscriber', (done) ->

    conf = getBasicConfig()

    subQueue =
      push: (job, cb) ->
        assert.equal job.action, 'create'
        assert.equal job.name, 'test-model'

        doc = job.current
        assert.equal doc._id, 'none!name'
        assert.ok doc.createdAt
        assert.equal doc.keyPart1, 'none'
        assert.equal doc.keyPart2, 'name'
        assert.equal doc.version, 'test-version'

        done()

    conf.subscriberQueues.push subQueue

    sourceDoc =
      current: {keyPart1: 'none', keyPart2: 'name'}

    conf.sourceStream = es.duplex [
      es.through()
      es.readArray [sourceDoc]
    ]...

    am = new AutoMerger conf

  it 'should push to three subscribers', (done) ->
    checklist = {}

    getQueue = (name) ->
      minimalQueueStub =
        push: (item, cb) ->
          checklist[name] = true
          if checklist.q1 and checklist.q2 and checklist.q3
            assert.ok 'all subscriber queues received message'
            done()

      return minimalQueueStub


    conf = getBasicConfig()
    conf.subscriberQueues = ((getQueue "q#{i}") for i in [1..3])

    sourceDoc =
      current: {keyPart1: 'none', keyPart2: 'name'}

    conf.sourceStream = es.duplex [
      es.through()
      es.readArray [sourceDoc]
    ]...

    am = new AutoMerger conf

  it 'should write cbId to sourceStream after db save', (done) ->

    conf = getBasicConfig()

    sourceDoc =
      cbId: 'someId-from-client'
      current: {keyPart1: 'none', keyPart2: 'name'}

    conf.sourceStream = es.duplex [
      es.through (cbId) ->
        assert.equal cbId, sourceDoc.cbId, 'cbId received by sourceStream should match expected'
        done()
      es.readArray [sourceDoc]
    ]...

    am = new AutoMerger conf

  it 'should migrate', (done) ->
    conf = getBasicConfig()
    existingDoc = {field1: 'ok', another: true}

    # an existing document is returned by `find`
    conf.db.find = (id, cb) -> cb null, existingDoc

    sub =
      push: (job) ->
        # subscriptionStream receives the migrated document
        assert.equal job.current.field2, 'sure'
        assert.equal job.current.field3, true

        done()

    conf.subscriberQueues.push sub

    conf.migrator = (doc) ->
      # check initial state
      assert.deepEqual doc, existingDoc

      # do migration
      delete doc.field1
      delete doc.another
      doc.field2 = 'sure'
      doc.field3 = true

      return doc

    sourceDoc =
      current: {keyPart1: 'none', keyPart2: 'name'}

    conf.sourceStream = es.duplex [
      es.through()
      es.readArray [sourceDoc]
    ]...

    am = new AutoMerger conf

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

    conf.subscriberQueues.push push: onJob

    sourceDoc =
      current: {keyPart1: 'none', keyPart2: 'name'}

    conf.sourceStream = es.duplex [
      es.through()
      es.readArray [sourceDoc]
    ]...

    am = new AutoMerger conf

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
    conf.subscriberQueues.push push: onJob

    sourceDoc =
      current:
        keyPart1: 'none'
        keyPart2: 'name'
        nonKeyField: true

    conf.sourceStream = es.duplex [
      es.through()
      es.readArray [sourceDoc]
    ]...

    am = new AutoMerger conf

  it 'model should emit "source-reject" with rejectSource fn', (done) ->
    conf = getBasicConfig()
    conf.rejectSource = (doc) -> return true # always reject
    conf.db.upsert = -> assert.fail 'should not save a rejected document'
    conf.subscriberQueues.push push: ->
      assert.fail 'should not notify subscribers of rejected docs'

    sourceDoc =
      current:
        keyPart1: 'none'
        keyPart2: 'name'
        nonKeyField: true

    conf.sourceStream = es.duplex [
      es.through()
      es.readArray [sourceDoc]
    ]...

    am = new AutoMerger conf

    am.on 'source-reject', (doc) ->
      assert.ok doc, 'rejected document as expected'
      done()

  it 'model should emit "source-reject" with incomplete id', (done) ->
    conf = getBasicConfig()
    conf.db.upsert = -> assert.fail 'should not save a rejected document'
    conf.subscriberQueues.push push: ->
      assert.fail 'should not notify subscribers of rejected docs'

    sourceDoc =
      current:
        keyPart1: 'none'
        # keyPart2: 'name' # source is missing keyPart2, an idPiece
        nonKeyField: true

    conf.sourceStream = es.duplex [
      es.through()
      es.readArray [sourceDoc]
    ]...

    am = new AutoMerger conf
    am.on 'source-reject', (doc) ->
      assert.ok doc, 'rejected document as expected'
      done()

  it 'should emit "source-reject" with unchanged target', (done) ->
    originalTarget = _id: 'none!name', keyPart1: 'none', keyPart2: 'name', createdAt: (new Date).toString()

    conf = getBasicConfig()

    conf.db.find = (id, cb) -> cb null, originalTarget
    conf.db.upsert = -> assert.fail 'should not save a rejected document'

    conf.subscriberQueues.push push: ->
      assert.fail 'should not notify subscribers of rejected docs'

    sourceDoc =
      current:
        keyPart1: 'none'
        keyPart2: 'name'

    conf.sourceStream = es.duplex [
      es.through()
      es.readArray [sourceDoc]
    ]...

    am = new AutoMerger conf
    am.on 'source-reject', (doc) ->
      assert.ok doc, 'rejected document as expected'
      done()

  it '"target-not-ready" should save target and emit event', (done) ->
    conf = getBasicConfig()
    conf.readyProperties = ['readyField']

    savedTarget = false

    conf.db.upsert = (id, doc, cb) ->
      savedTarget = true
      assert.ok id
      assert.ok doc
      cb null

    conf.subscriberQueues.push push: ->
      assert.fail 'should not notify subscribers of unready docs'

    sourceDoc =
      current:
        keyPart1: 'none'
        keyPart2: 'name'
        nonKeyField: true
        # readyField: true #readyProperty not present

    conf.sourceStream = es.duplex [
      es.through()
      es.readArray [sourceDoc]
    ]...

    am = new AutoMerger conf

    am.on 'target-not-ready', (doc) ->
      assert.ok doc, 'document not ready as expected'
      assert.ok savedTarget
      done()

